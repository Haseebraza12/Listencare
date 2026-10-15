import 'conversation.dart';
import '../../captions/domain/speech_engine.dart';
import '../../captions/domain/note_preferences.dart';

class SavedState {
  const SavedState({
    this.conversations = const [],
    this.recentSearches = const [],
    this.language = CaptionLanguage.english,
    this.mode = RecognitionMode.device,
    this.captionSize = 22,
    this.draftText = '',
    this.draftId,
    this.draftSeconds = 0,
    this.noteFont = NoteFont.inter,
    this.animationsEnabled = true,
  });
  final List<Conversation> conversations;
  final List<String> recentSearches;
  final CaptionLanguage language;
  final RecognitionMode mode;
  final double captionSize;
  final String draftText;
  final String? draftId;
  final int draftSeconds;
  final NoteFont noteFont;
  final bool animationsEnabled;
}

abstract interface class LocalStore {
  Future<SavedState> read();
  Future<void> write(SavedState state);
}
