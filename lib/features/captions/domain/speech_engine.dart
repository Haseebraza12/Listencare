enum CaptionLanguage {
  english('English', 'en', 'en-US'),
  urdu('اردو', 'ur', 'ur-PK');

  const CaptionLanguage(this.label, this.code, this.preferredLocale);
  final String label;
  final String code;
  final String preferredLocale;
}

enum RecognitionMode { device, offline }

class SpeechUpdate {
  const SpeechUpdate(this.words, {this.isFinal = false});
  final String words;
  final bool isFinal;
}

/// A replaceable platform boundary. Results are cumulative snapshots for ONE
/// listening session, never text to append per callback.
abstract interface class SpeechEngine {
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  });
  Future<List<String>> locales();
  Future<void> listen({
    required String locale,
    required bool offline,
    required void Function(SpeechUpdate) onResult,
  });
  Future<void> stop();
  Future<void> cancel();
}
