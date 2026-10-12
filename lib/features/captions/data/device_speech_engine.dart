import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../domain/speech_engine.dart';

class DeviceSpeechEngine implements SpeechEngine {
  final SpeechToText _speech = SpeechToText();
  static const _capabilities = MethodChannel('listencare/speech_capabilities');
  Completer<void>? _pendingStop;

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
    return _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && !(_pendingStop?.isCompleted ?? true)) {
          _pendingStop!.complete();
        }
        onStatus(status);
      },
      onError: (error) {
        if (!(_pendingStop?.isCompleted ?? true)) _pendingStop!.complete();
        onError(error.errorMsg);
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
    await _speech.listen(
      onResult: (result) => onResult(
        SpeechUpdate(result.recognizedWords, isFinal: result.finalResult),
      ),
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 5),
        onDevice: offline,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() async {
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
    }
  }

  @override
  Future<void> cancel() => _speech.cancel();
}
