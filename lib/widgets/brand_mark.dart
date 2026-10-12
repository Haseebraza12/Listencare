import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// The same speech-bubble and sound-wave mark as assets/brand/listencare.svg.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ListenCare',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: Palette.gradient,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: CustomPaint(painter: _MarkPainter()),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(26, 25)
        ..lineTo(73, 25)
        ..quadraticBezierTo(82, 25, 82, 34)
        ..lineTo(82, 62)
        ..quadraticBezierTo(82, 71, 73, 71)
        ..lineTo(48, 71)
        ..lineTo(30, 82)
        ..lineTo(30, 71)
        ..lineTo(26, 71)
        ..quadraticBezierTo(18, 71, 18, 62)
        ..lineTo(18, 34)
        ..quadraticBezierTo(18, 25, 26, 25),
      paint,
    );
    for (final bar in [
      (33.0, 43.0, 54.0),
      (44.0, 36.0, 60.0),
      (55.0, 40.0, 56.0),
      (66.0, 45.0, 52.0),
    ]) {
      canvas.drawLine(Offset(bar.$1, bar.$2), Offset(bar.$1, bar.$3), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
