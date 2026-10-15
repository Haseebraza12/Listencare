import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// A listening indicator, not a simulated audio meter.
class MicrophoneControl extends StatefulWidget {
  const MicrophoneControl({
    super.key,
    required this.listening,
    required this.connecting,
    required this.animationsEnabled,
    required this.onPressed,
  });
  final bool listening;
  final bool connecting;
  final bool animationsEnabled;
  final VoidCallback? onPressed;
  @override
  State<MicrophoneControl> createState() => _MicrophoneControlState();
}

class _MicrophoneControlState extends State<MicrophoneControl>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MicrophoneControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.listening &&
        widget.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    height: 80,
    child: Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Transform.scale(
              key: const ValueKey('microphone-pulse'),
              scale: 1 + _pulse.value * .16,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.listening
                      ? Palette.purple.withValues(alpha: .16)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: Palette.gradient,
          ),
          child: IconButton(
            onPressed: widget.onPressed,
            tooltip: widget.connecting
                ? 'Cancel microphone startup'
                : widget.listening
                ? 'Pause listening'
                : 'Start listening',
            icon: Icon(
              widget.connecting
                  ? Icons.close_rounded
                  : widget.listening
                  ? Icons.pause_rounded
                  : Icons.mic_none_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
