/// Replaces a session hypothesis, preserving corrections and intentional repeats.
class TranscriptBuffer {
  String _completed = '';
  String _hypothesis = '';
  String get text {
    if (_completed.isEmpty) return _hypothesis;
    if (_hypothesis.isEmpty) return _completed;
    final separator = RegExp(r'\s$').hasMatch(_completed) ? '' : ' ';
    return '$_completed$separator$_hypothesis';
  }

  void replace(String text) {
    _completed = text;
    _hypothesis = '';
  }

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
