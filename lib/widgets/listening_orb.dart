import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/palette.dart';

class ListeningOrb extends StatefulWidget {
  const ListeningOrb({super.key, required this.active, required this.duration});
  final bool active;
  final String duration;
  @override
  State<ListeningOrb> createState() => _ListeningOrbState();
}

class _ListeningOrbState extends State<ListeningOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ListeningOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _RibbonPainter(_animation)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: Palette.gradient.createShader,
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: Palette.gradient.createShader,
                child: Text(
                  widget.duration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .38;
    final bounds = Offset.zero & size;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          const Color(0xFFDFC9F6).withValues(alpha: .14),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [.5, .76, 1],
      ).createShader(bounds);
    canvas.drawCircle(center, size.width * .5, halo);
    final shader = Palette.gradient.createShader(bounds);
    final phase = animation.value * math.pi * 2;
    for (var ribbon = 0; ribbon < 18; ribbon++) {
      final path = Path();
      for (var step = 0; step <= 180; step++) {
        final angle = step / 180 * math.pi * 2;
        final wave =
            math.sin(angle * 3 + ribbon * .36 + phase) * 11 +
            math.cos(angle * 5 - ribbon * .22) * 4;
        final r = radius + wave + math.sin(ribbon * .8) * 9;
        final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = ribbon % 4 == 0 ? 7 : 1
          ..color = Colors.white.withValues(alpha: ribbon % 4 == 0 ? .12 : .2)
          ..blendMode = BlendMode.srcOver,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
