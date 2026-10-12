import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/speech_engine.dart';
import '../domain/transcript_buffer.dart';
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
  bool _disposed = false;
  bool _initialized = false;
  bool _saving = false;
  bool _storageHealthy = true;
  int _generation = 0;
  CaptureState state = CaptureState.idle;
  CaptionLanguage language = CaptionLanguage.english;
  RecognitionMode mode = RecognitionMode.device;
  double captionSize = 22;
  String? error;
  List<Conversation> _conversations = [];
  List<String> _recentSearches = [];

  String get transcript => _buffer.text;
  bool get isListening => state == CaptureState.listening;
  bool get isBusy =>
      state == CaptureState.starting ||
      state == CaptureState.stopping ||
      _saving;
  bool get hasDraft => transcript.isNotEmpty;
  int get elapsedSeconds => _clock.elapsed.inSeconds;
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
      state = CaptureState.listening;
      _clock.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
      _emit();
      await _engine.listen(
        locale: locale,
        offline: mode == RecognitionMode.offline,
        onResult: (result) {
          if (_disposed || generation != _generation) return;
          // Interim and final callbacks replace the SAME session hypothesis.
          _buffer.update(result.words);
          _emit();
        },
      );
    } catch (exception) {
      if (!_disposed && generation == _generation) {
        _fail(_messageFor(exception.toString()));
      }
    }
  }

  Future<void> stop() async {
    if (_disposed ||
        state == CaptureState.idle ||
        state == CaptureState.stopping) {
      return;
    }
    if (state == CaptureState.starting) {
      ++_generation;
      _finish();
      await _engine.cancel();
      return;
    }
    state = CaptureState.stopping;
    _emit();
    try {
      // Accept the final result returned after stop().
      await _engine.stop();
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
    // notListening can precede the final transcript; wait for done/stop instead.
    if (status == 'done' && state != CaptureState.stopping) _finish();
  }

  void _onError(String message) => _fail(_messageFor(message));
  String _messageFor(String message) {
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
      return 'No speech was detected. Tap the microphone to try again.';
    }
    return 'Speech recognition stopped. Check your device’s speech service and connection, then try again.';
  }

  void _fail(String message) {
    error = message;
    _finish();
  }

  void _finish() {
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    state = CaptureState.idle;
    _emit();
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
    error = null;
    _finish();
  }

  Future<bool> saveConversation() async {
    if (_saving || !hasDraft || state != CaptureState.idle) return false;
    _saving = true;
    ++_generation;
    _emit();
    final now = DateTime.now();
    final item = Conversation(
      id: now.microsecondsSinceEpoch.toString(),
      text: transcript,
      language: language,
      createdAt: now,
      durationSeconds: elapsedSeconds,
    );
    final next = [item, ..._conversations];
    final saved = await _persist(conversations: next);
    if (saved && !_disposed) {
      _conversations = next;
      _buffer.clear();
      _clock.reset();
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
    if (saved) _conversations = next;
    _saving = false;
    _emit();
    return saved;
  }

  Future<bool> updateSettings({
    CaptionLanguage? language,
    RecognitionMode? mode,
    double? captionSize,
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
    );
    if (saved) {
      this.language = language ?? this.language;
      this.mode = mode ?? this.mode;
      this.captionSize = captionSize ?? this.captionSize;
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
  }) async {
    if (!_storageHealthy) {
      error =
          'Saved data could not be read. Restart the app before saving changes; your existing data has been preserved.';
      _emit();
      return false;
    }
    try {
      await _store.write(
        SavedState(
          conversations: conversations ?? _conversations,
          recentSearches: searches ?? _recentSearches,
          language: language ?? this.language,
          mode: mode ?? this.mode,
          captionSize: captionSize ?? this.captionSize,
        ),
      );
      error = null;
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
    _disposed = true;
    ++_generation;
    _ticker?.cancel();
    _clock.stop();
    unawaited(_engine.cancel().catchError((Object _) {}));
    super.dispose();
  }
}
