import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  final Widget child;
  final double gridSpacing;
  final Color? gridColor;
  final double opacity;

  const GridBackground({
    super.key,
    required this.child,
    this.gridSpacing = 30.0,
    this.gridColor,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final color = gridColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    return CustomPaint(
      painter: GridPainter(
        spacing: gridSpacing,
        color: color.withOpacity(opacity),
      ),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  final double spacing;
  final Color color;

  GridPainter({required this.spacing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
