import 'dart:async';
import 'package:listencare/features/captions/domain/speech_engine.dart';
import 'package:listencare/features/library/domain/local_store.dart';

class FakeSpeechEngine implements SpeechEngine {
  void Function(String)? status;
  void Function(String)? error;
  void Function(SpeechUpdate)? result;
  bool available = true;
  List<String> availableLocales = ['en_US', 'ur_PK'];
  String? selectedLocale;
  bool? selectedOffline;
  int starts = 0;
  int initializations = 0;
  int cancellations = 0;
  Completer<bool>? initialization;
  Completer<void>? stopping;
  String? finalOnStop;

  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  }) async {
    initializations++;
    status = onStatus;
    error = onError;
    return initialization == null ? available : initialization!.future;
  }

  @override
  Future<List<String>> locales() async => availableLocales;
  @override
  Future<void> listen({
    required String locale,
    required bool offline,
    required void Function(SpeechUpdate) onResult,
  }) async {
    starts++;
    selectedLocale = locale;
    selectedOffline = offline;
    result = onResult;
  }

  void emit(String words, {bool finalResult = false}) =>
      result?.call(SpeechUpdate(words, isFinal: finalResult));
  @override
  Future<void> stop() async {
    if (stopping != null) await stopping!.future;
    if (finalOnStop != null) emit(finalOnStop!, finalResult: true);
    status?.call('done');
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }
}

class MemoryStore implements LocalStore {
  SavedState state = const SavedState();
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? pendingWrite;
  @override
  Future<SavedState> read() async {
    if (failRead) throw StateError('read failed');
    return state;
  }

  @override
  Future<void> write(SavedState value) async {
    if (pendingWrite != null) await pendingWrite!.future;
    if (failWrite) throw StateError('write failed');
    state = value;
  }
}
