import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/features/captions/domain/transcript_buffer.dart';

void main() {
  test('CAP-01 cumulative interim and duplicate final results appear once', () {
    final buffer = TranscriptBuffer()..beginSession();
    for (final words in [
      'hello',
      'hello world',
      'hello world',
      'hello world',
    ]) {
      buffer.update(words);
    }
    expect(buffer.text, 'hello world');
  });
  test(
    'CAP-02 corrections replace the hypothesis and preserve repeated words',
    () {
      final buffer = TranscriptBuffer()
        ..beginSession()
        ..update('very very god')
        ..update('very very good');
      expect(buffer.text, 'very very good');
    },
  );
  test('CAP-03 distinct sessions preserve intentionally repeated phrases', () {
    final buffer = TranscriptBuffer()
      ..beginSession()
      ..update('hello world')
      ..beginSession()
      ..update('hello world');
    expect(buffer.text, 'hello world hello world');
  });
  test(
    'CAP-02 Urdu cumulative results are replaced without word splitting',
    () {
      final buffer = TranscriptBuffer()
        ..beginSession()
        ..update('آپ')
        ..update('آپ کیسے ہیں')
        ..update('آپ کیسے ہیں');
      expect(buffer.text, 'آپ کیسے ہیں');
    },
  );
}
