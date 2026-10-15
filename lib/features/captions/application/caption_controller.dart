import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/speech_engine.dart';
import '../domain/transcript_buffer.dart';
import '../domain/note_preferences.dart';
import '../../library/domain/local_store.dart';
import '../../library/domain/conversation.dart';

enum CaptureState { idle, starting, listening, stopping }

class CaptionController extends ChangeNotifier {
  CaptionController({required this._engine, required this._store});
  final SpeechEngine _engine;
  final LocalStore _store;
  final TranscriptBuffer _buffer = TranscriptBuffer();
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  Timer? _draftTimer;
  Timer? _settlingTimer;
  Future<void>? _stopFuture;
  Future<void>? _writes;
  int _draftRevision = 0;
  int _savedRevision = 0;
  bool draftSaveFailed = false;
  int _savedSeconds = 0;
  String? _editingId;
  bool _disposed = false;
  bool _initialized = false;
  bool _endedDuringStart = false;
  bool _saving = false;
  bool _storageHealthy = true;
  int _generation = 0;
  CaptureState state = CaptureState.idle;
  CaptionLanguage language = CaptionLanguage.english;
  RecognitionMode mode = RecognitionMode.device;
  double captionSize = 22;
  NoteFont noteFont = NoteFont.inter;
  bool animationsEnabled = true;
  String? error;
  List<Conversation> _conversations = [];
  List<String> _recentSearches = [];

  String get transcript => _buffer.text;
  bool get isListening => state == CaptureState.listening;
  bool get isSaving => _saving;
  bool get draftMatchesSaved => _conversations.any(
    (note) => note.id == _editingId && note.text == transcript,
  );
  bool get isBusy =>
      state == CaptureState.starting ||
      state == CaptureState.stopping ||
      _saving;
  bool get hasDraft => transcript.trim().isNotEmpty;
  bool get draftSaved => _savedRevision == _draftRevision;
  String? get editingId => _editingId;
  bool get canOpenSpeechSettings =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      _engine is SpeechSettings;
  Future<void> openSpeechSettings() async {
    if (_engine case final SpeechSettings settings) {
      try {
        await settings.openSettings();
      } catch (_) {
        error =
            'Open your device Settings to check the speech service and microphone permissions.';
        _emit();
      }
    }
  }

  int get elapsedSeconds => _savedSeconds + _clock.elapsed.inSeconds;
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> load() async {
    try {
      final saved = await _store.read();
      if (_disposed) return;
      _conversations = List.of(saved.conversations);
      _recentSearches = List.of(saved.recentSearches);
      language = saved.language;
      mode = saved.mode;
      captionSize = saved.captionSize;
      noteFont = saved.noteFont;
      animationsEnabled = saved.animationsEnabled;
      _buffer.replace(saved.draftText);
      _editingId = saved.draftId;
      _savedSeconds = saved.draftSeconds;
      _storageHealthy = true;
    } catch (_) {
      _storageHealthy = false;
      error =
          'Saved data could not be loaded. Existing data has been preserved. Restart the app to try again.';
    }
    _emit();
  }

  Future<void> start() async {
    if (_disposed || state != CaptureState.idle || _saving) return;
    error = null;
    state = CaptureState.starting;
    _endedDuringStart = false;
    _settlingTimer?.cancel();
    final generation = ++_generation;
    _emit();
    try {
      if (!_initialized) {
        _initialized = await _engine.initialize(
          onStatus: _onStatus,
          onError: _onError,
        );
      }
      if (_disposed || generation != _generation) return;
      if (!_initialized) {
        _fail(
          error ??
              'Speech is unavailable. Allow microphone and speech permissions in your device settings.',
        );
        return;
      }
      final available = await _engine.locales();
      if (_disposed || generation != _generation) return;
      String? locale;
      for (final candidate in available) {
        if (candidate.replaceAll('_', '-').toLowerCase() ==
            language.preferredLocale.toLowerCase()) {
          locale = candidate;
          break;
        }
      }
      locale ??= available
          .where(
            (candidate) =>
                candidate.split(RegExp('[-_]')).first.toLowerCase() ==
                language.code,
          )
          .firstOrNull;
      // Some engines enumerate only offline packs. Try the selected locale
      // explicitly rather than rejecting valid network Urdu recognition.
      locale ??= language.preferredLocale;
      _buffer.beginSession();
      await _engine.listen(
        locale: locale,
        offline: mode == RecognitionMode.offline,
        onResult: (result) {
          if (_disposed || generation != _generation) return;
          // Interim and final callbacks replace the SAME session hypothesis.
          _buffer.update(result.words);
          _scheduleDraftSave();
          _emit();
        },
      );
      if (_disposed ||
          generation != _generation ||
          state != CaptureState.starting) {
        return;
      }
      state = CaptureState.listening;
      if (_endedDuringStart) {
        _finish();
        return;
      }
      _clock.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
      _emit();
    } catch (exception) {
      if (!_disposed && generation == _generation) {
        _fail(_messageFor(exception.toString()));
      }
    }
  }

  Future<void> stop() {
    if (_disposed || state == CaptureState.idle) return Future.value();
    return _stopFuture ??= _stopCapture().whenComplete(
      () => _stopFuture = null,
    );
  }

  Future<void> _stopCapture() async {
    final wasStarting = state == CaptureState.starting;
    if (wasStarting) ++_generation;
    _settlingTimer?.cancel();
    state = CaptureState.stopping;
    _emit();
    try {
      // Accept the final result returned after stop().
      if (wasStarting) {
        await _engine.cancel();
      } else {
        await _engine.stop();
      }
    } catch (_) {
      error =
          'The microphone could not stop normally. Your captions are still here.';
      try {
        await _engine.cancel();
      } catch (_) {
        /* Preserve the draft. */
      }
    } finally {
      _finish();
    }
  }

  void _onStatus(String status) {
    if (status == 'done' && state == CaptureState.starting) {
      _endedDuringStart = true;
    }
    // notListening can precede the final transcript; wait for done/stop instead.
    if (status == 'done' && state == CaptureState.listening) _finish();
    if (status == 'notListening' && state == CaptureState.listening) {
      _settlingTimer?.cancel();
      _settlingTimer = Timer(const Duration(seconds: 3), () {
        if (state == CaptureState.listening) _finish();
      });
    }
  }

  void _onError(String message) {
    if (state == CaptureState.starting || state == CaptureState.listening) {
      _fail(_messageFor(message));
    }
  }

  String _messageFor(String message) {
    if (message.contains('speech_service_unavailable')) {
      return 'No speech recognition service is installed or enabled on this Android device. Enable a speech provider in device Settings, or use an emulator with a Google Play system image. You can still type, edit, and save notes.';
    }
    if (message.contains('permission') || message.contains('denied')) {
      return 'Microphone or speech permission was denied. Enable it in your device settings and try again.';
    }
    if (mode == RecognitionMode.offline) {
      return 'Offline speech is unavailable for ${language.label} on this device. Install an offline language pack or choose Device service in Settings. No online fallback was used.';
    }
    if (message.contains('language') || message.contains('locale')) {
      return '${language.label} speech is unavailable on this device. Install the language in your device’s speech settings or select another language.';
    }
    if (message.contains('no_match') || message.contains('speech_timeout')) {
      return 'No speech was detected. Your note is safe. Check microphone input, then tap the microphone to try again.';
    }
    if (message.contains('audio')) {
      return 'The speech service could not access audio. Check microphone access for ListenCare and the Google app. On an emulator, enable host microphone input. You can keep typing.';
    }
    if (message.contains('busy') || message.contains('client')) {
      return 'The speech service is busy. Wait a moment and retry. Your typed note and captions are preserved.';
    }
    if (message.contains('network') || message.contains('server')) {
      return 'The speech service could not connect. Check internet access or choose Offline only if a language pack is installed. You can keep typing.';
    }
    return 'Dictation could not start ($message). Check your device’s speech service and microphone input. Your note is safe; you can keep typing.';
  }

  void _fail(String message) {
    ++_generation;
    error = message;
    _finish();
  }

  void _finish() {
    _settlingTimer?.cancel();
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    state = CaptureState.idle;
    if (!_disposed) _scheduleDraftSave();
    _emit();
  }

  void updateDraft(String text) {
    if (_disposed || state != CaptureState.idle || _saving) return;
    ++_generation;
    _buffer.replace(text);
    _scheduleDraftSave();
    _emit();
  }

  void _scheduleDraftSave() {
    draftSaveFailed = false;
    _draftRevision++;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(flushDraft()),
    );
  }

  Future<void> flushDraft() async {
    _draftTimer?.cancel();
    if (_disposed || draftSaved || _saving) return;
    draftSaveFailed = !await _persist(clearError: false);
    if (!draftSaveFailed &&
        error?.startsWith('Changes could not be saved.') == true) {
      error = null;
    }
    _emit();
  }

  Future<bool> openConversation(Conversation note) async {
    if (_disposed || state != CaptureState.idle || _saving) return false;
    ++_generation;
    _editingId = note.id;
    _buffer.replace(note.text);
    language = note.language;
    _clock.reset();
    _savedSeconds = note.durationSeconds;
    error = null;
    _scheduleDraftSave();
    _emit();
    return true;
  }

  Future<void> clear() async {
    if (_saving) return;
    ++_generation;
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    state = CaptureState.stopping;
    _emit();
    try {
      await _engine.cancel();
    } catch (_) {
      /* Already idle. */
    }
    if (_disposed) return;
    _buffer.clear();
    _clock.reset();
    _savedSeconds = 0;
    _editingId = null;
    error = null;
    _finish();
  }

  Future<bool> saveConversation({bool keepOpen = false}) async {
    if (_saving || !hasDraft || state != CaptureState.idle) return false;
    _saving = true;
    ++_generation;
    _emit();
    final now = DateTime.now();
    final existing = _conversations
        .where((note) => note.id == _editingId)
        .firstOrNull;
    final item = Conversation(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      text: transcript,
      language: language,
      createdAt: existing?.createdAt ?? now,
      durationSeconds: elapsedSeconds,
    );
    final next = [item, ..._conversations.where((note) => note.id != item.id)];
    _draftTimer?.cancel();
    final saved = await _persist(
      conversations: next,
      clearDraft: !keepOpen,
      draftId: keepOpen ? item.id : null,
    );
    if (saved && !_disposed) {
      _conversations = next;
      if (keepOpen) {
        _editingId = item.id;
      } else {
        _buffer.clear();
        _clock.reset();
        _savedSeconds = 0;
        _editingId = null;
      }
      _savedRevision = _draftRevision;
    }
    _saving = false;
    _emit();
    return saved;
  }

  Future<bool> deleteConversation(String id) async {
    if (_saving) return false;
    _saving = true;
    final next = _conversations.where((item) => item.id != id).toList();
    final saved = await _persist(conversations: next);
    if (saved) {
      _conversations = next;
      if (_editingId == id) {
        _editingId = null;
        _scheduleDraftSave();
      }
    }
    _saving = false;
    _emit();
    return saved;
  }

  Future<bool> updateSettings({
    CaptionLanguage? language,
    RecognitionMode? mode,
    double? captionSize,
    NoteFont? noteFont,
    bool? animationsEnabled,
  }) async {
    if (isBusy || state != CaptureState.idle) return false;
    if (hasDraft && language != null && language != this.language) {
      error =
          'Save or clear your current conversation before changing its language.';
      _emit();
      return false;
    }
    _saving = true;
    final saved = await _persist(
      language: language,
      mode: mode,
      captionSize: captionSize,
      noteFont: noteFont,
      animationsEnabled: animationsEnabled,
    );
    if (saved) {
      this.language = language ?? this.language;
      this.mode = mode ?? this.mode;
      this.captionSize = captionSize ?? this.captionSize;
      this.noteFont = noteFont ?? this.noteFont;
      this.animationsEnabled = animationsEnabled ?? this.animationsEnabled;
    }
    _saving = false;
    _emit();
    return saved;
  }

  Future<void> rememberSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty || _saving) return;
    _saving = true;
    final next = [
      query,
      ..._recentSearches.where((item) => item != query),
    ].take(6).toList();
    if (await _persist(searches: next)) _recentSearches = next;
    _saving = false;
    _emit();
  }

  Future<void> removeSearch(String query) async {
    if (_saving) return;
    _saving = true;
    final next = _recentSearches.where((item) => item != query).toList();
    if (await _persist(searches: next)) _recentSearches = next;
    _saving = false;
    _emit();
  }

  Future<bool> _persist({
    List<Conversation>? conversations,
    List<String>? searches,
    CaptionLanguage? language,
    RecognitionMode? mode,
    double? captionSize,
    NoteFont? noteFont,
    bool? animationsEnabled,
    String? draftId,
    bool clearDraft = false,
    bool clearError = true,
  }) async {
    if (!_storageHealthy) {
      error =
          'Saved data could not be read. Restart the app before saving changes; your existing data has been preserved.';
      _emit();
      return false;
    }
    final revision = _draftRevision;
    final snapshot = SavedState(
      conversations: conversations ?? List.of(_conversations),
      recentSearches: searches ?? List.of(_recentSearches),
      language: language ?? this.language,
      mode: mode ?? this.mode,
      captionSize: captionSize ?? this.captionSize,
      noteFont: noteFont ?? this.noteFont,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      draftText: clearDraft ? '' : transcript,
      draftId: clearDraft ? null : draftId ?? _editingId,
      draftSeconds: clearDraft ? 0 : elapsedSeconds,
    );
    try {
      final previous = _writes;
      final completer = Completer<void>();
      _writes = completer.future;
      try {
        if (previous != null) await previous;
        await _store.write(snapshot);
      } finally {
        completer.complete();
      }
      if (!clearDraft) _savedRevision = revision;
      if (clearError) error = null;
      return true;
    } catch (_) {
      error =
          'Changes could not be saved. Your current conversation is still here. Please try again.';
      return false;
    }
  }

  void dismissError() {
    error = null;
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    unawaited(flushDraft());
    _disposed = true;
    ++_generation;
    _ticker?.cancel();
    _draftTimer?.cancel();
    _settlingTimer?.cancel();
    _clock.stop();
    unawaited(_engine.cancel().catchError((Object _) {}));
    super.dispose();
  }
}
