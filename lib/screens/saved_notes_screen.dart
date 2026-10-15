import 'package:flutter/material.dart';
import '../features/captions/application/caption_controller.dart';
import '../features/captions/domain/speech_engine.dart';
import '../features/library/domain/conversation.dart';
import '../widgets/design_components.dart';
import '../theme/palette.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({
    super.key,
    required this.controller,
    required this.onOpen,
  });
  final CaptionController controller;
  final Future<bool> Function(Conversation) onOpen;
  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  final _search = TextEditingController();
  CaptionLanguage? _language;
  bool _opening = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(Conversation note) async {
    if (_opening) return;
    setState(() => _opening = true);
    final opened = await widget.onOpen(note);
    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
    } else {
      setState(() => _opening = false);
    }
  }

  Future<void> _delete(Conversation note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This removes the saved copy from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteConversation(note.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved notes')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final query = _search.text.trim().toLowerCase();
            final notes = c.conversations
                .where(
                  (note) =>
                      note.text.toLowerCase().contains(query) &&
                      (_language == null || note.language == _language),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const ValueKey('notes-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: c.rememberSearch,
                  decoration: InputDecoration(
                    hintText: 'Search notes',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Palette.lavender,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final language in CaptionLanguage.values)
                      FilterChip(
                        label: Text(language.label),
                        selected: _language == language,
                        onSelected: (selected) => setState(
                          () => _language = selected ? language : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (c.error != null && !c.error!.contains('speech recognition service'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      c.error!,
                      style: const TextStyle(color: Palette.purple),
                    ),
                  ),
                if (notes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      c.conversations.isEmpty
                          ? 'No saved notes yet. Write a note, then choose Save note from the top menu.'
                          : 'No notes match your search.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Palette.muted),
                    ),
                  )
                else
                  ...notes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Palette.lavender,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          onTap: _opening ? null : () => _open(note),
                          title: Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: note.language == CaptionLanguage.urdu
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                          subtitle: Text(
                            '${note.language.label} · ${formatDate(note.createdAt)}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete note',
                            onPressed: _opening ? null : () => _delete(note),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
