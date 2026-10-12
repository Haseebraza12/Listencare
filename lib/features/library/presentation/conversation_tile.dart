import 'package:flutter/material.dart';
import '../domain/conversation.dart';
import '../../captions/domain/speech_engine.dart';
import '../../../theme/palette.dart';
import '../../../widgets/design_components.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onOpen,
  });
  final Conversation conversation;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final note = conversation;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Palette.lavender.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onOpen,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          title: Text(
            note.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: note.language == CaptionLanguage.urdu
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${note.language.label} · ${formatDate(note.createdAt)} · ${formatDuration(note.durationSeconds)}',
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        ),
      ),
    );
  }
}
