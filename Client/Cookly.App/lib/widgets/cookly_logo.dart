import 'package:flutter/material.dart';

import '../theme/cookly_colors.dart';

/// The Cookly brand mark (steam + flame + leaf), redrawn from the Stitch
/// design's 100x100 viewBox SVG so it renders crisply at any size without
/// a network image dependency.
class CooklyLogo extends StatelessWidget {
  const CooklyLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CooklyLogoPainter()),
    );
  }
}

class _CooklyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = CooklyColors.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stemPath = Path()
      ..moveTo(36, 84)
      ..cubicTo(27, 84, 20, 78, 20, 68)
      ..cubicTo(20, 62, 23, 57, 28, 54.5)
      ..cubicTo(27, 52, 26.5, 49, 26.5, 46)
      ..cubicTo(26.5, 35, 34.5, 26, 44.5, 25)
      ..cubicTo(47, 18, 53.5, 13, 61.5, 13)
      ..cubicTo(71.5, 13, 79.5, 21, 79.5, 31)
      ..cubicTo(84.5, 33.5, 88, 38.5, 88, 44.5)
      ..cubicTo(88, 52, 82.5, 58, 75.5, 59.5)
      ..cubicTo(76.5, 62, 77, 64.5, 77, 67.5)
      ..cubicTo(77, 76.5, 70, 84, 61, 84);
    canvas.drawPath(stemPath, strokePaint);

    final flamePaint = Paint()
      ..color = CooklyColors.primaryContainer
      ..style = PaintingStyle.fill;
    final flamePath = Path()
      ..moveTo(49, 28)
      ..cubicTo(53, 35, 60, 40, 57, 51)
      ..cubicTo(62, 46, 64, 40, 64, 36)
      ..cubicTo(69, 42, 70, 51, 66, 59)
      ..cubicTo(63, 65, 56, 68, 50, 68)
      ..cubicTo(42, 68, 36, 62, 36, 54)
      ..cubicTo(36, 44, 43, 37, 49, 28)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    final leafPaint = Paint()
      ..color = CooklyColors.tertiaryContainer
      ..style = PaintingStyle.fill;
    final leafPath = Path()
      ..moveTo(22, 68)
      ..cubicTo(22, 79, 32, 87, 45, 87)
      ..cubicTo(62, 87, 74, 76, 74, 65)
      ..cubicTo(62, 65, 54, 75, 42, 75)
      ..cubicTo(34, 75, 27, 72, 22, 68)
      ..close();
    canvas.drawPath(leafPath, leafPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CooklyLogoPainter oldDelegate) => false;
}
