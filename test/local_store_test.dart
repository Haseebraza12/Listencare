import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:listencare/features/library/data/local_store.dart';
import 'package:listencare/features/library/domain/local_store.dart';
import 'package:listencare/features/library/domain/conversation.dart';
import 'package:listencare/features/captions/domain/speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'NOTE-02 existing v2 library without draft fields remains readable',
    () async {
      SharedPreferences.setMockInitialValues({
        PreferencesStore.key:
            '{"schemaVersion":2,"conversations":[{"id":"old","text":"Existing note","language":"english","createdAt":"2026-10-01T12:00:00.000","durationSeconds":10}],"recentSearches":[],"language":"english","mode":"device","captionSize":22}',
      });
      final state = await PreferencesStore().read();
      expect(state.conversations.single.text, 'Existing note');
      expect(state.draftText, isEmpty);
      expect(state.draftId, isNull);
    },
  );
  test(
    'SET-01/LIB-01 actual preference adapter round-trips Urdu and settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PreferencesStore();
      await store.write(
        SavedState(
          language: CaptionLanguage.urdu,
          mode: RecognitionMode.offline,
          captionSize: 30,
          recentSearches: ['سلام'],
          draftText: 'مسودہ\n\nنوٹ',
          draftId: '1',
          draftSeconds: 12,
          conversations: [
            Conversation(
              id: '1',
              text: 'سلام',
              language: CaptionLanguage.urdu,
              createdAt: DateTime(2026, 10, 12),
              durationSeconds: 12,
            ),
          ],
        ),
      );
      final loaded = await store.read();
      expect(loaded.language, CaptionLanguage.urdu);
      expect(loaded.mode, RecognitionMode.offline);
      expect(loaded.captionSize, 30);
      expect(loaded.conversations.single.text, 'سلام');
      expect(loaded.recentSearches.single, 'سلام');
      expect(loaded.draftText, 'مسودہ\n\nنوٹ');
      expect(loaded.draftId, '1');
      expect(loaded.draftSeconds, 12);
    },
  );
  test('DATA-01 corrupt document throws and remains untouched', () async {
    SharedPreferences.setMockInitialValues({PreferencesStore.key: '{invalid'});
    await expectLater(
      PreferencesStore().read(),
      throwsA(isA<FormatException>()),
    );
    expect(
      (await SharedPreferences.getInstance()).getString(PreferencesStore.key),
      '{invalid',
    );
  });
  test(
    'DATA-01 an unknown schema version is preserved instead of guessed',
    () async {
      const raw = '{"schemaVersion":3,"conversations":[]}';
      SharedPreferences.setMockInitialValues({PreferencesStore.key: raw});
      await expectLater(
        PreferencesStore().read(),
        throwsA(isA<FormatException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString(PreferencesStore.key),
        raw,
      );
    },
  );
}
