import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/conversation.dart';
import '../domain/local_store.dart';
import '../../captions/domain/speech_engine.dart';

/// A single versioned document avoids partial settings/library writes.
class PreferencesStore implements LocalStore {
  static const key = 'listencare.state.v2';
  @override
  Future<SavedState> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null) return const SavedState();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schemaVersion'] != 2) {
      throw const FormatException('Unsupported saved-data version.');
    }
    return SavedState(
      conversations: (json['conversations'] as List)
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentSearches: (json['recentSearches'] as List).cast<String>(),
      language: CaptionLanguage.values.byName(json['language'] as String),
      mode: RecognitionMode.values.byName(json['mode'] as String),
      captionSize: (json['captionSize'] as num).toDouble().clamp(18, 36),
    );
  }

  @override
  Future<void> write(SavedState state) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      key,
      jsonEncode({
        'schemaVersion': 2,
        'conversations': state.conversations
            .map((item) => item.toJson())
            .toList(),
        'recentSearches': state.recentSearches,
        'language': state.language.name,
        'mode': state.mode.name,
        'captionSize': state.captionSize,
      }),
    );
    if (!saved) throw StateError('The device could not save your changes.');
  }
}
