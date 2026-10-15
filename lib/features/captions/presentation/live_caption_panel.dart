import 'package:flutter/material.dart';
import '../application/caption_controller.dart';
import '../domain/speech_engine.dart';
import '../../../theme/palette.dart';
import '../../../widgets/brand_mark.dart';
import '../../../widgets/design_components.dart';
import '../../../widgets/microphone_control.dart';

enum NoteAction { save, copy, newNote }

class LiveCaptionPanel extends StatefulWidget {
  const LiveCaptionPanel({
    super.key,
    required this.controller,
    required this.onNotes,
    required this.onSettings,
    required this.onSave,
    required this.onClear,
    required this.onCopy,
  });
  final CaptionController controller;
  final VoidCallback onNotes;
  final VoidCallback onSettings;
  final Future<void> Function() onSave;
  final Future<void> Function() onClear;
  final Future<void> Function(String) onCopy;
  @override
  State<LiveCaptionPanel> createState() => _LiveCaptionPanelState();
}

class _LiveCaptionPanelState extends State<LiveCaptionPanel> {
  late final TextEditingController _editor;
  CaptionController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    _editor = TextEditingController(text: c.transcript);
  }

  @override
  void didUpdateWidget(covariant LiveCaptionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editor.text != c.transcript) {
      _editor.value = TextEditingValue(
        text: c.transcript,
        selection: TextSelection.collapsed(offset: c.transcript.length),
      );
    }
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  Future<void> _toggleMicrophone() async {
    FocusScope.of(context).unfocus();
    if (c.state == CaptureState.starting || c.isListening) {
      await c.stop();
    } else {
      await c.start();
    }
  }

  Future<void> _errorDetails() async {
    final message = c.error;
    if (message == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dictation or saving needs attention'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          if (c.canOpenSpeechSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                c.openSpeechSettings();
              },
              child: const Text('Speech settings'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep typing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (c.draftSaveFailed) {
                c.flushDraft();
              } else {
                c.start();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
    child: Row(
      children: [
        const BrandMark(size: 34),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Notepad',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Saved notes',
          onPressed: widget.onNotes,
          icon: const Icon(Icons.folder_open_outlined),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: widget.onSettings,
          icon: const Icon(Icons.tune_rounded),
        ),
        IconButton(
          key: const ValueKey('clear-notepad'),
          tooltip: 'Clear notepad',
          onPressed: c.hasDraft && !c.isSaving ? widget.onClear : null,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        PopupMenuButton<NoteAction>(
          tooltip: 'Note actions',
          onSelected: (action) async {
            switch (action) {
              case NoteAction.save:
                await widget.onSave();
              case NoteAction.copy:
                await widget.onCopy(c.transcript);
              case NoteAction.newNote:
                await widget.onClear();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: NoteAction.save,
              enabled: c.hasDraft && !c.isSaving,
              child: Text(c.editingId == null ? 'Save note' : 'Save changes'),
            ),
            PopupMenuItem(
              value: NoteAction.copy,
              enabled: c.hasDraft,
              child: const Text('Copy text'),
            ),
            PopupMenuItem(
              value: NoteAction.newNote,
              enabled: !c.isSaving,
              child: const Text('New note'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _note(double? height) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Palette.line),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.error != null)
              Material(
                color: Palette.lavender,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                child: InkWell(
                  onTap: _errorDetails,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Palette.purple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.draftSaveFailed
                                ? 'Draft not saved. Tap for help.'
                                : 'Dictation unavailable. Tap for help.',
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss message',
                          onPressed: c.dismissError,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: TextField(
                key: const ValueKey('note-editor'),
                controller: _editor,
                onChanged: c.updateDraft,
                readOnly: c.state != CaptureState.idle || c.isSaving,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                textDirection: c.language == CaptionLanguage.urdu
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(
                  inherit: false,
                  textBaseline: TextBaseline.alphabetic,
                  fontFamily: c.noteFont.family,
                  fontFamilyFallback: const ['NotoNaskhArabic'],
                  color: Palette.ink,
                  fontSize: c.captionSize,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write a note…\nOr tap the microphone to dictate.',
                  contentPadding: EdgeInsets.all(20),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _microphone() {
    final status = switch (c.state) {
      CaptureState.starting => 'Connecting… Tap to cancel',
      CaptureState.listening =>
        'Listening · ${formatDuration(c.elapsedSeconds)}',
      CaptureState.stopping => 'Finishing dictation…',
      CaptureState.idle =>
        c.hasDraft ? 'Tap to add dictation' : 'Tap microphone to dictate',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
      child: Row(
        children: [
          MicrophoneControl(
            listening: c.isListening,
            connecting: c.state == CaptureState.starting,
            animationsEnabled: c.animationsEnabled,
            onPressed: c.state == CaptureState.stopping || c.isSaving
                ? null
                : _toggleMicrophone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: widget.onSettings,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${c.language.label} · ${c.mode == RecognitionMode.offline ? 'Offline only' : 'Device service'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFFCFAFF),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 310) {
          return ListView(children: [_header(), _note(190), _microphone()]);
        }
        return Column(
          children: [
            _header(),
            Expanded(child: _note(null)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                c.draftSaveFailed
                    ? 'Draft not saved · tap the message above for help'
                    : !c.hasDraft
                    ? 'Your notes stay on this device'
                    : c.draftSaved
                    ? 'Saved on this device'
                    : 'Saving draft…',
                maxLines: 2,
                style: const TextStyle(fontSize: 11, color: Palette.muted),
              ),
            ),
            _microphone(),
          ],
        );
      },
    ),
  );
}
