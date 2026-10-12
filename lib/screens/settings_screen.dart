import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/captions/application/caption_controller.dart';
import '../features/captions/domain/speech_engine.dart';
import '../theme/palette.dart';
import '../widgets/brand_mark.dart';
import '../widgets/design_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final CaptionController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CaptionController get controller => widget.controller;
  double? _previewSize;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final enabled = c.state == CaptureState.idle && !c.isBusy;
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Row(
                  children: [
                    BrandMark(size: 52),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ListenCare',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'A little closer, word by word.',
                            style: TextStyle(
                              color: Palette.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Speech & language',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you listen and the language you speak.',
                  style: TextStyle(color: Palette.muted),
                ),
                const SizedBox(height: 20),
                if (!enabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Pause listening before changing your settings.',
                      style: TextStyle(color: Palette.purple),
                    ),
                  ),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recognition language',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<CaptionLanguage>(
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
                              ? (value) =>
                                    c.updateSettings(language: value.first)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Urdu captions use right-to-left text. Language support depends on your device’s speech service.',
                        style: TextStyle(color: Palette.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Speech recognition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mode(
                        context,
                        RecognitionMode.device,
                        'Device service',
                        'Lightweight speech recognition built into your phone or browser. May send audio to its service and require internet.',
                        Icons.graphic_eq_rounded,
                        enabled,
                      ),
                      const Divider(height: 24),
                      _mode(
                        context,
                        RecognitionMode.offline,
                        'Offline only',
                        kIsWeb
                            ? 'Use the mobile app for offline-only recognition. Browsers cannot guarantee offline processing.'
                            : 'Requests on-device recognition only. Requires a supported device and installed language pack; Urdu offline support varies.',
                        Icons.wifi_off_rounded,
                        enabled && !kIsWeb,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Caption appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                if (mounted) {
                                  setState(() => _previewSize = null);
                                }
                              }
                            : null,
                      ),
                      Text(
                        c.language == CaptionLanguage.urdu
                            ? 'ہر لفظ، آپ کو قریب لائے۔'
                            : 'Every word brings us closer.',
                        textDirection: c.language == CaptionLanguage.urdu
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: _previewSize ?? c.captionSize,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Your conversations, your device',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved captions stay in this app’s local storage. ListenCare does not record or save audio. Device service mode follows your speech provider’s processing policy. Uninstalling the app or clearing browser data removes saved conversations.',
                  style: TextStyle(
                    color: Palette.muted,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Listening may stop automatically after a pause or a device-imposed limit. Your captions stay here; tap the microphone to continue.',
                  style: TextStyle(
                    color: Palette.muted,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      c.error!,
                      style: const TextStyle(color: Color(0xFFA23D61)),
                    ),
                  ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'ListenCare 2.0',
                    style: TextStyle(color: Palette.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _mode(
    BuildContext context,
    RecognitionMode mode,
    String title,
    String subtitle,
    IconData icon,
    bool enabled,
  ) => InkWell(
    onTap: enabled ? () => controller.updateSettings(mode: mode) : null,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: enabled ? Palette.purple : Palette.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Palette.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            selected: controller.mode == mode,
            button: true,
            label: title,
            enabled: enabled,
            child: Icon(
              controller.mode == mode
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: controller.mode == mode ? Palette.purple : Palette.muted,
              size: 23,
            ),
          ),
        ],
      ),
    ),
  );
}
