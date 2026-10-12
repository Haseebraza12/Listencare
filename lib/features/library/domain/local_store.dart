import 'conversation.dart';
import '../../captions/domain/speech_engine.dart';

class SavedState {
  const SavedState({
    this.conversations = const [],
    this.recentSearches = const [],
    this.language = CaptionLanguage.english,
    this.mode = RecognitionMode.device,
    this.captionSize = 22,
  });
  final List<Conversation> conversations;
  final List<String> recentSearches;
  final CaptionLanguage language;
  final RecognitionMode mode;
  final double captionSize;
}

abstract interface class LocalStore {
  Future<SavedState> read();
  Future<void> write(SavedState state);
}
