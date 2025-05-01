import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static final StreamController<String> _streamController = StreamController<String>.broadcast();

  static Future<Stream<String>> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        _streamController.add(result.recognizedWords); // Emit recognized words to the stream
      });
    }
    return _streamController.stream;
  }

  static Future<void> stop() async {
    await _speech.stop();
    _streamController.close(); // Close the stream when stopping
  }
}