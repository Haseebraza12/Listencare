import 'package:flutter/material.dart';
import '../../captions/application/caption_controller.dart';
import '../../captions/domain/speech_engine.dart';
import '../domain/conversation.dart';
import '../../../theme/palette.dart';
import '../../../widgets/design_components.dart';
import 'conversation_tile.dart';

class SearchPanel extends StatefulWidget {
  const SearchPanel({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onSettings,
    required this.onOpenConversation,
  });
  final CaptionController controller;
  final void Function(int) onNavigate;
  final VoidCallback onSettings;
  final void Function(Conversation) onOpenConversation;
  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  CaptionController get c => widget.controller;
  void _go(int tab) => widget.onNavigate(tab);
  void _settings() => widget.onSettings();
  Widget _header({
    String? title,
    Widget? leading,
    required List<Widget> actions,
  }) => PanelHeader(
    title: title,
    leading: leading,
    actions: actions,
    onBack: () => _go(1),
  );
  Widget _noteTile(Conversation note) => ConversationTile(
    conversation: note,
    onOpen: () => widget.onOpenConversation(note),
  );
  final _search = TextEditingController();
  CaptionLanguage? _filter;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _searchPage();
  Widget _searchPage() {
    final query = _search.text.trim().toLowerCase();
    final matches = c.conversations
        .where(
          (note) =>
              (_filter == null || note.language == _filter) &&
              note.text.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      children: [
        _header(
          title: 'Search',
          actions: [
            CircleAction(
              icon: Icons.filter_alt_outlined,
              label: 'Filter by language',
              onPressed: _showFilter,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  gradient: Palette.gradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: c.rememberSearch,
                  decoration: InputDecoration(
                    hintText: 'Search your conversations…',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Palette.purple,
                    ),
                    suffixIcon: query.isEmpty
                        ? const Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color: Palette.purple,
                          )
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(_search.clear),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if (query.isEmpty && _filter == null) ...[
                Text(
                  'Explore your conversations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _suggestion(
                  'English conversations',
                  Palette.purple,
                  () => setState(() {
                    _filter = CaptionLanguage.english;
                    _search.clear();
                  }),
                ),
                _suggestion(
                  'اردو میں گفتگو',
                  const Color(0xFF42ADE7),
                  () => setState(() {
                    _filter = CaptionLanguage.urdu;
                    _search.clear();
                  }),
                ),
                _suggestion(
                  'All saved conversations',
                  const Color(0xFFEAB849),
                  () => setState(() {
                    _filter = null;
                    _search.clear();
                  }),
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent searches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (c.recentSearches.isEmpty)
                  const Text(
                    'Your searches will appear here.',
                    style: TextStyle(color: Palette.muted, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: c.recentSearches
                        .map(
                          (query) => InputChip(
                            label: Text(
                              query,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () =>
                                setState(() => _search.text = query),
                            onDeleted: () => c.removeSearch(query),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Palette.line),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Go to…',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _go(0),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.mic_none_rounded,
                        color: Palette.purple,
                        size: 18,
                      ),
                      label: const Text('Live captions'),
                      onPressed: () => _go(1),
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Palette.pink,
                        size: 18,
                      ),
                      label: const Text('My conversations'),
                      onPressed: () => _go(0),
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF42ADE7),
                        size: 18,
                      ),
                      label: const Text('Settings'),
                      onPressed: _settings,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _filter == null
                          ? 'Saved conversations'
                          : '${_filter!.label} conversations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${matches.length}',
                    style: const TextStyle(color: Palette.muted),
                  ),
                ],
              ),
              if (_filter != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _filter = null),
                    child: const Text('Show all languages'),
                  ),
                ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    c.conversations.isEmpty
                        ? 'Nothing saved yet. Your conversations will find a home here.'
                        : 'No conversations match this search.',
                    style: const TextStyle(color: Palette.muted, height: 1.7),
                  ),
                )
              else
                ...matches.map(_noteTile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestion(String label, Color color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.ink,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          side: const BorderSide(color: Palette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Icon(Icons.auto_awesome_rounded, color: color, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    ),
  );

  Future<void> _showFilter() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Filter by language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final language in [null, ...CaptionLanguage.values])
              ListTile(
                title: Text(language?.label ?? 'All languages'),
                trailing: _filter == language
                    ? const Icon(Icons.check, color: Palette.purple)
                    : null,
                onTap: () {
                  setState(() => _filter = language);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
