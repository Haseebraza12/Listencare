import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/captions/application/caption_controller.dart';
import '../features/captions/presentation/live_caption_panel.dart';
import '../features/library/domain/conversation.dart';
import 'saved_notes_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final CaptionController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CaptionController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission prompts temporarily make the app inactive during startup.
    if (state == AppLifecycleState.inactive &&
        c.state == CaptureState.starting) {
      return;
    }
    if (state != AppLifecycleState.resumed) {
      unawaited(() async {
        await c.stop();
        await c.flushDraft();
      }());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.dispose();
    super.dispose();
  }

  Future<void> _settings() async {
    FocusScope.of(context).unfocus();
    await c.stop();
    await c.flushDraft();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: SettingsScreen(controller: c),
      ),
    );
  }

  Future<void> _notes() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await c.stop();
    await c.flushDraft();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SavedNotesScreen(controller: c, onOpen: _editNote),
      ),
    );
  }

  Future<bool> _editNote(Conversation note) async {
    if (c.editingId == note.id) return true;
    if (c.hasDraft && !c.draftMatchesSaved) {
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Save your current note first?'),
          content: const Text('Keep your draft before opening another note.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save and open'),
            ),
          ],
        ),
      );
      if (save != true || !await c.saveConversation()) return false;
    }
    return c.openConversation(note);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note copied'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await c.stop();
    final saved = await c.saveConversation(keepOpen: true);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clear() async {
    FocusScope.of(context).unfocus();
    await c.stop();
    if (!mounted) return;
    if (c.hasDraft && !c.draftMatchesSaved) {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start a new note?'),
          content: const Text('Save this note or discard its draft.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'discard'),
              child: const Text('Discard draft'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'save'),
              child: const Text('Save and start new'),
            ),
          ],
        ),
      );
      if (action == null) return;
      if (action == 'save' && !await c.saveConversation()) return;
    }
    await c.clear();
    await c.flushDraft();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFCFAFF),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListenableBuilder(
            listenable: c,
            builder: (_, _) => LiveCaptionPanel(
              controller: c,
              onNotes: _notes,
              onSettings: _settings,
              onSave: _save,
              onClear: _clear,
              onCopy: _copy,
            ),
          ),
        ),
      ),
    ),
  );
}
