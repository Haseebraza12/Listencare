import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/captions/application/caption_controller.dart';
import '../features/captions/domain/speech_engine.dart';
import '../features/library/domain/conversation.dart';
import '../theme/palette.dart';
import '../widgets/design_components.dart';
import 'settings_screen.dart';
import '../features/captions/presentation/live_caption_panel.dart';
import '../features/library/presentation/conversation_panel.dart';
import '../features/library/presentation/search_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final CaptionController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 1;
  CaptionController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(c.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.dispose();
    super.dispose();
  }

  void _settings() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => SettingsScreen(controller: c)),
  );
  void _go(int tab) => setState(() => _tab = tab);
  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation copied')));
    }
  }

  Future<void> _save() async {
    final saved = await c.saveConversation();
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation saved on this device')),
      );
    }
  }

  Future<void> _clear() async {
    if (!c.hasDraft) {
      await c.clear();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this conversation?'),
        content: const Text('Unsaved captions will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (discard == true) await c.clear();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;
        if (wide) {
          final panelHeight = (constraints.maxHeight - 180).clamp(660.0, 832.0);
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.2, .85),
                  radius: 1.15,
                  colors: [
                    Color(0xFF91809F),
                    Color(0xFF3D2567),
                    Color(0xFF24094C),
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 70,
                    horizontal: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1272),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 54),
                            child: _desktopPanel(_overview(), panelHeight),
                          ),
                        ),
                        const SizedBox(width: 60),
                        Expanded(child: _desktopPanel(_live(), panelHeight)),
                        const SizedBox(width: 60),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 54),
                            child: _desktopPanel(_searchPage(), panelHeight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _tab,
              children: [_overview(), _live(), _searchPage()],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _go,
            backgroundColor: Colors.white,
            indicatorColor: Palette.lavender,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                label: 'Conversations',
              ),
              NavigationDestination(
                icon: Icon(Icons.mic_none_rounded),
                label: 'Listen',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _desktopPanel(Widget child, double height) => Container(
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(42),
      border: Border.all(color: Colors.white.withValues(alpha: .6)),
    ),
    child: child,
  );

  Widget _live() => LiveCaptionPanel(
    controller: c,
    onNavigate: _go,
    onSettings: _settings,
    onSave: _save,
    onClear: _clear,
    onCopy: _copy,
  );
  Widget _overview() => ConversationPanel(
    controller: c,
    onNavigate: _go,
    onSettings: _settings,
    onOpenConversation: _openNote,
  );
  Widget _searchPage() => SearchPanel(
    controller: c,
    onNavigate: _go,
    onSettings: _settings,
    onOpenConversation: _openNote,
  );

  Future<void> _openNote(Conversation note) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .65,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Conversation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${formatDate(note.createdAt)} · ${note.language.label}',
                style: const TextStyle(color: Palette.muted),
              ),
              const SizedBox(height: 24),
              SelectableText(
                note.text,
                textDirection: note.language == CaptionLanguage.urdu
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(fontSize: c.captionSize, height: 1.7),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: () => _copy(note.text),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final delete = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete this conversation?'),
                          content: const Text(
                            'This removes the saved conversation from this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Keep'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (delete == true) {
                        final saved = await c.deleteConversation(note.id);
                        if (saved && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
