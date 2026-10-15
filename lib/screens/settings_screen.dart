import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/captions/application/caption_controller.dart';
import '../features/captions/domain/speech_engine.dart';
import '../features/captions/domain/note_preferences.dart';
import '../theme/palette.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final CaptionController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _previewSize;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final enabled = c.state == CaptureState.idle && !c.isBusy;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            tooltip: 'Close settings',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'Notepad appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NoteFont>(
                  key: const ValueKey('note-font-setting'),
                  initialValue: c.noteFont,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Font',
                    border: OutlineInputBorder(),
                  ),
                  items: NoteFont.values
                      .map(
                        (font) => DropdownMenuItem(
                          value: font,
                          child: Text(font.label),
                        ),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (font) => c.updateSettings(noteFont: font)
                      : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Text('Text size')),
                    Text('${(_previewSize ?? c.captionSize).round()} px'),
                  ],
                ),
                Slider(
                  value: _previewSize ?? c.captionSize,
                  min: 18,
                  max: 36,
                  divisions: 9,
                  label: '${(_previewSize ?? c.captionSize).round()} px',
                  onChanged: enabled
                      ? (value) => setState(() => _previewSize = value)
                      : null,
                  onChangeEnd: enabled
                      ? (value) async {
                          await c.updateSettings(captionSize: value);
                          if (mounted) setState(() => _previewSize = null);
                        }
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.lavender,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    c.language == CaptionLanguage.urdu
                        ? 'آپ کا نوٹ، آپ کے الفاظ۔'
                        : 'Your note, your words.',
                    textDirection: c.language == CaptionLanguage.urdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      inherit: false,
                      fontSize: _previewSize ?? c.captionSize,
                      fontFamily: c.noteFont.family,
                      fontFamilyFallback: const ['NotoNaskhArabic'],
                      height: 1.6,
                      color: Palette.ink,
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Microphone animation'),
                  subtitle: const Text(
                    'Pulse while listening. Reduced-motion preferences are respected.',
                  ),
                  value: c.animationsEnabled,
                  onChanged: enabled
                      ? (value) => c.updateSettings(animationsEnabled: value)
                      : null,
                ),
                const Divider(height: 32),
                Text(
                  'Dictation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SegmentedButton<CaptionLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: CaptionLanguage.english,
                      label: Text('English'),
                    ),
                    ButtonSegment(
                      value: CaptionLanguage.urdu,
                      label: Text('اردو'),
                    ),
                  ],
                  selected: {c.language},
                  onSelectionChanged: enabled
                      ? (selection) =>
                            c.updateSettings(language: selection.first)
                      : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Save or clear an unsaved note before changing its language.',
                  style: TextStyle(fontSize: 12, color: Palette.muted),
                ),
                const SizedBox(height: 16),
                for (final mode in RecognitionMode.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      mode == RecognitionMode.device
                          ? 'Device service'
                          : 'Offline only',
                    ),
                    subtitle: Text(
                      mode == RecognitionMode.device
                          ? 'Uses the device speech provider; internet may be required.'
                          : kIsWeb
                          ? 'Unavailable in browsers.'
                          : 'Requires an on-device recognizer and installed language pack.',
                    ),
                    leading: Icon(
                      c.mode == mode
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: Palette.purple,
                    ),
                    onTap:
                        enabled && (!kIsWeb || mode != RecognitionMode.offline)
                        ? () => c.updateSettings(mode: mode)
                        : null,
                  ),
                if (c.canOpenSpeechSettings)
                  TextButton.icon(
                    onPressed: c.openSpeechSettings,
                    icon: const Icon(Icons.settings_voice_outlined),
                    label: const Text('Device speech settings'),
                  ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      c.error!,
                      style: const TextStyle(color: Palette.purple),
                    ),
                  ),
                const Divider(height: 32),
                const Text(
                  'Typing always works without the microphone. Dictation can pause after silence; tap the microphone to continue. Audio is not saved. Notes and settings stay on this device.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Palette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ListenCare 2.1',
                  style: TextStyle(fontSize: 12, color: Palette.muted),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
