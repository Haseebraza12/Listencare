import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../domain/speech_engine.dart';

class DeviceSpeechEngine implements SpeechEngine, SpeechSettings {
  DeviceSpeechEngine({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();
  final SpeechToText _speech;
  static const _capabilities = MethodChannel('listencare/speech_capabilities');
  Completer<void>? _pendingStop;
  Completer<bool>? _pendingStart;
  Future<void>? _cleanup;
  bool _sessionActive = false;
  int _session = 0;
  String? _lastFailure;

  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      onError(
        'Speech recognition is unavailable on Linux. Use Android, iOS, macOS, or a supported browser.',
      );
      return false;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final available = await _capabilities.invokeMethod<bool>(
        'isRecognitionAvailable',
      );
      if (available != true) {
        onError('speech_service_unavailable');
        return false;
      }
    }
    return _speech.initialize(
      onStatus: (status) {
        if (_cleanup != null ||
            (!_sessionActive &&
                _pendingStart == null &&
                _pendingStop == null)) {
          return;
        }
        if (status == 'listening' && !(_pendingStart?.isCompleted ?? true)) {
          _pendingStart!.complete(true);
        }
        if (status == 'done' && !(_pendingStart?.isCompleted ?? true)) {
          _pendingStart!.complete(false);
        }
        if (status == 'done' && !(_pendingStop?.isCompleted ?? true)) {
          _pendingStop!.complete();
        }
        if (status == 'done') _sessionActive = false;
        onStatus(status);
      },
      onError: (error) {
        if (!_sessionActive || _cleanup != null) return;
        final session = _session;
        final pendingStart = _pendingStart;
        final pendingStop = _pendingStop;
        _sessionActive = false;
        _lastFailure = error.errorMsg;
        final cleanup = _speech.cancel().catchError((Object _) {});
        _cleanup = cleanup;
        unawaited(
          cleanup.then((_) {
            if (identical(_cleanup, cleanup)) _cleanup = null;
            if (session != _session) return;
            if (!(pendingStart?.isCompleted ?? true)) {
              pendingStart!.complete(false);
            }
            if (!(pendingStop?.isCompleted ?? true)) pendingStop!.complete();
            onError(error.errorMsg);
          }),
        );
      },
    );
  }

  @override
  Future<List<String>> locales() async =>
      (await _speech.locales()).map((locale) => locale.localeId).toList();

  @override
  Future<void> listen({
    required String locale,
    required bool offline,
    required void Function(SpeechUpdate) onResult,
  }) async {
    await _cleanup;
    if (offline && kIsWeb) {
      throw UnsupportedError(
        'Offline-only speech is available in the mobile app.',
      );
    }
    if (offline && !kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // The package can fall back to a network recognizer on older Android.
        // Gate on a real API-31+ local recognizer before passing onDevice=true.
        final supported = await _capabilities.invokeMethod<bool>(
          'supportsOffline',
        );
        if (supported != true) {
          throw UnsupportedError('Offline recognition is unavailable.');
        }
      } else if (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        throw UnsupportedError('Offline recognition is unavailable.');
      }
    }
    final pending = Completer<bool>();
    _pendingStart = pending;
    final session = ++_session;
    _sessionActive = true;
    _lastFailure = null;
    try {
      await _speech.listen(
        onResult: (result) {
          if (session == _session && (_sessionActive || _pendingStop != null)) {
            onResult(
              SpeechUpdate(result.recognizedWords, isFinal: result.finalResult),
            );
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 10),
          onDevice: offline,
          partialResults: true,
          // Cleanup finishes before the app offers retry; a delayed automatic
          // cancel must never terminate a newly started session.
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
      final started = await pending.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!started) {
        final failure =
            _lastFailure ??
            _speech.lastError?.errorMsg ??
            'speech_service_not_started';
        await cancel();
        throw StateError(failure);
      }
    } catch (_) {
      if (session == _session) await cancel();
      rethrow;
    } finally {
      if (identical(_pendingStart, pending)) _pendingStart = null;
    }
  }

  @override
  Future<void> stop() async {
    await _cleanup;
    if (!_sessionActive && !_speech.isListening) return;
    final pending = Completer<void>();
    _pendingStop = pending;
    try {
      await _speech.stop();
      await pending.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    } finally {
      _pendingStop = null;
      _sessionActive = false;
    }
  }

  @override
  Future<void> cancel() async {
    ++_session;
    _sessionActive = false;
    if (!(_pendingStart?.isCompleted ?? true)) _pendingStart!.complete(false);
    await _cleanup;
    await _speech.cancel();
  }

  @override
  Future<void> openSettings() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _capabilities.invokeMethod<void>('openSpeechSettings');
    }
  }
}
