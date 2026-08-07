import 'package:flutter/material.dart';

/// The FreshFold logomark — a shirt-on-hanger glyph inside a rounded tile.
/// Reused on the splash and login screens per the design source.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.tileColor = Colors.white24,
    this.iconColor = Colors.white,
    this.radius,
  });

  final double size;
  final Color tileColor;
  final Color iconColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(radius ?? size * 0.29),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size * 0.5, size * 0.5),
        painter: _ShirtHangerPainter(color: iconColor),
      ),
    );
  }
}

class _ShirtHangerPainter extends CustomPainter {
  _ShirtHangerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;

    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale);

    // Hanger body — rounded rect (shirt on a hanger silhouette).
    canvas.drawRRect(
      RRect.fromRectAndRadius(r(4, 3, 16, 18), Radius.circular(2 * scale)),
      stroke,
    );
    // Hanger hook — outer + inner circle.
    canvas.drawCircle(Offset(12 * scale, 13 * scale), 5 * scale, stroke);
    canvas.drawCircle(Offset(12 * scale, 13 * scale), 2 * scale, stroke);
    // Two collar buttons.
    canvas.drawCircle(Offset(7 * scale, 6 * scale), 0.8 * scale, dot);
    canvas.drawCircle(Offset(9.5 * scale, 6 * scale), 0.8 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant _ShirtHangerPainter oldDelegate) =>
      oldDelegate.color != color;
}
