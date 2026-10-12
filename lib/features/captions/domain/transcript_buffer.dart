/// Replaces a session hypothesis, preserving corrections and intentional repeats.
class TranscriptBuffer {
  String _completed = '';
  String _hypothesis = '';
  String get text =>
      [_completed, _hypothesis].where((part) => part.isNotEmpty).join(' ');

  void beginSession() {
    _completed = text;
    _hypothesis = '';
  }

  void update(String words) => _hypothesis = words.trim();
  void clear() {
    _completed = '';
    _hypothesis = '';
  }
}
