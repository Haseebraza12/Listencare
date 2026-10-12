import 'package:flutter/material.dart';
import '../application/caption_controller.dart';
import '../domain/speech_engine.dart';
import '../../../theme/palette.dart';
import '../../../widgets/design_components.dart';
import '../../../widgets/listening_orb.dart';

class LiveCaptionPanel extends StatefulWidget {
  const LiveCaptionPanel({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onSettings,
    required this.onSave,
    required this.onClear,
    required this.onCopy,
  });
  final CaptionController controller;
  final void Function(int) onNavigate;
  final VoidCallback onSettings;
  final Future<void> Function() onSave;
  final Future<void> Function() onClear;
  final Future<void> Function(String) onCopy;
  @override
  State<LiveCaptionPanel> createState() => _LiveCaptionPanelState();
}

class _LiveCaptionPanelState extends State<LiveCaptionPanel> {
  CaptionController get c => widget.controller;
  void _go(int tab) => widget.onNavigate(tab);
  void _settings() => widget.onSettings();
  Future<void> _save() => widget.onSave();
  Future<void> _clear() => widget.onClear();
  Future<void> _copy(String text) => widget.onCopy(text);
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
  @override
  Widget build(BuildContext context) => _live();
  Widget _live() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFBF5FB),
          Colors.white,
          Colors.white,
          Color(0xFFFCF1E8),
        ],
        stops: [0, .25, .7, 1],
      ),
    ),
    child: Column(
      children: [
        _header(
          title: 'Live captions',
          leading: CircleAction(
            icon: Icons.chevron_left_rounded,
            label: 'Conversations',
            onPressed: () => _go(0),
          ),
          actions: [
            CircleAction(
              icon: Icons.more_horiz_rounded,
              label: 'Settings',
              onPressed: _settings,
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: ListeningOrb(
                    active: c.isListening,
                    duration: formatDuration(c.elapsedSeconds),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  c.isListening
                      ? 'Listening to you…'
                      : c.hasDraft
                      ? 'Conversation paused'
                      : 'Every word, a little closer.',
                  style: TextStyle(
                    fontSize: 16,
                    color: c.isListening ? Palette.ink : Palette.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinePill(
                      label: c.language.label,
                      icon: Icons.language_rounded,
                      selected: true,
                      onTap: _settings,
                    ),
                    OutlinePill(
                      label: c.mode == RecognitionMode.offline
                          ? 'Offline only'
                          : 'Device service',
                      icon: c.mode == RecognitionMode.offline
                          ? Icons.wifi_off_rounded
                          : Icons.graphic_eq_rounded,
                      onTap: _settings,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (c.error != null) _errorCard(),
                if (c.hasDraft)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      border: Border.all(color: Palette.line),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: SelectableText(
                      c.transcript,
                      textDirection: c.language == CaptionLanguage.urdu
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: c.captionSize,
                        height: 1.65,
                        color: Palette.ink,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      c.isListening
                          ? 'Your words will appear here as you speak.'
                          : 'Turn conversations into clear, live text.\nTap the microphone to begin.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Palette.muted,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ),
                if (c.hasDraft)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copy(c.transcript),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy'),
                        ),
                        TextButton.icon(
                          onPressed: c.state == CaptureState.idle && !c.isBusy
                              ? _save
                              : null,
                          icon: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 18,
                          ),
                          label: const Text('Save conversation'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 20, 48, 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: c.isBusy ? null : _clear,
                tooltip: 'Clear conversation',
                icon: const Icon(
                  Icons.stop_rounded,
                  color: Palette.muted,
                  size: 30,
                ),
              ),
              CircleAction(
                size: 70,
                gradient: true,
                icon: c.isListening
                    ? Icons.pause_rounded
                    : Icons.mic_none_rounded,
                label: c.isListening ? 'Pause listening' : 'Start listening',
                onPressed: c.isBusy
                    ? null
                    : () => c.isListening ? c.stop() : c.start(),
              ),
              IconButton(
                onPressed: c.isBusy
                    ? null
                    : () => c.isListening ? c.stop() : c.start(),
                tooltip: c.isListening ? 'Stop listening' : 'Resume listening',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Palette.muted,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _errorCard() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: Palette.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.info_outline_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(c.error!, style: const TextStyle(fontSize: 13))),
          IconButton(
            onPressed: c.dismissError,
            tooltip: 'Dismiss message',
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    ),
  );
}
