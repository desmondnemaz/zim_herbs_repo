import 'package:flutter/material.dart';

class ChevronPatternPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  ChevronPatternPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    const double rowHeight = 12.0;
    const double chevronWidth = 20.0;
    const double chevronHeight = 8.0;

    for (double y = 0; y < size.height; y += rowHeight) {
      final path = Path();
      for (double x = 0; x < size.width + chevronWidth; x += chevronWidth) {
        if (x == 0) {
          path.moveTo(x, y + chevronHeight);
        }
        path.lineTo(x + chevronWidth / 2, y);
        path.lineTo(x + chevronWidth, y + chevronHeight);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ZimbabweWorkBackground extends StatelessWidget {
  final Widget child;
  final Color? patternColor;

  const ZimbabweWorkBackground({
    super.key,
    required this.child,
    this.patternColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: ChevronPatternPainter(
              color:
                  patternColor ??
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              strokeWidth: 1.0,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
