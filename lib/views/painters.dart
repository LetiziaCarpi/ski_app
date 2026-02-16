import 'package:flutter/material.dart';
import 'dart:math' as math;

class ArcGaugePainter extends CustomPainter {
  final int score;
  ArcGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height * 0.7,
    ); // Lower center to fit arch
    final radius = size.width / 2 - 5;

    // Configuration
    const startAngle = 180 * (math.pi / 180); // Start at West (180)
    const sweepAngle = 180 * (math.pi / 180); // Sweep 180 to East (0)
    const segmentCount = 5;
    const gapAngle = 5 * (math.pi / 180); // Gap between segments
    final segmentSweep =
        (sweepAngle - (gapAngle * (segmentCount - 1))) / segmentCount;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14; // Slightly thicker

    final colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFFFFA726), // Orange
      const Color(0xFFFFEE58), // Yellow
      const Color(0xFF9CCC65), // Light Green
      const Color(0xFF66BB6A), // Green
    ];

    // Draw Segments
    for (int i = 0; i < segmentCount; i++) {
      paint.color = colors[i];
      final segmentStart = startAngle + (segmentSweep + gapAngle) * i;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segmentStart,
        segmentSweep,
        false,
        paint,
      );
    }

    // Draw Indicator (Circle on the track)
    final normalizedScore = score.clamp(0, 100) / 100;
    // Map score to angle
    final currentAngle = startAngle + (sweepAngle * normalizedScore);

    final thumbRadius = 10.0;
    final thumbCenter = Offset(
      center.dx + radius * math.cos(currentAngle),
      center.dy + radius * math.sin(currentAngle),
    );

    // Black circle with white border
    final thumbPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    final thumbBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
    canvas.drawCircle(thumbCenter, thumbRadius, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw Ticks
    for (int i = 0; i < 360; i += 10) {
      // More frequent ticks
      final isCardinal = i % 90 == 0;
      final tickLength = isCardinal ? 6.0 : 3.0;
      final angle = i * math.pi / 180;

      final p1 = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }

    // Draw Labels (N, E, S, W)
    _drawText(canvas, center, radius - 15, 'N', -math.pi / 2);
    _drawText(canvas, center, radius - 15, 'E', 0);
    _drawText(canvas, center, radius - 15, 'S', math.pi / 2);
    _drawText(canvas, center, radius - 15, 'W', math.pi);

    // Draw Arrow (pointing West as per image)
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw a simple arrow or indicator if needed.
    // The image shows an arrow pointing West.
    final arrowPath = Path();
    // Tip at West
    final arrowTip = Offset(center.dx - radius + 20, center.dy);
    // Base near center
    // This is getting complex to draw manually.
    // I'll stick to the ticks and labels for now, and maybe a simple indicator.
    // The image has a specific arrow style.
    // Let's just draw a line with an arrowhead pointing West.

    final arrowLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw arrow pointing West
    final arrowEnd = Offset(center.dx - (radius * 0.6), center.dy);
    final arrowStart = Offset(
      center.dx + (radius * 0.3),
      center.dy,
    ); // Slightly offset from center

    // canvas.drawLine(arrowStart, arrowEnd, arrowLinePaint);

    // Actually, looking at the image, it's a stylized compass.
    // Let's just keep the ticks and labels for now to keep it clean,
    // or add a simple triangle pointer.

    // Let's add the arrow pointing West (Left)
    final path = Path();
    path.moveTo(center.dx - (radius * 0.7), center.dy); // Tip
    path.lineTo(center.dx - (radius * 0.5), center.dy - 4);
    path.lineTo(center.dx - (radius * 0.5), center.dy + 4);
    path.close();
    canvas.drawPath(path, arrowPaint);

    // Line part
    canvas.drawLine(
      Offset(center.dx - (radius * 0.5), center.dy),
      Offset(center.dx + (radius * 0.5), center.dy),
      arrowLinePaint,
    );

    // Small circle at the other end (East)
    canvas.drawCircle(
      Offset(center.dx + (radius * 0.5), center.dy),
      2,
      arrowPaint,
    );
  }

  void _drawText(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double angle,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset(
      center.dx + radius * math.cos(angle) - textPainter.width / 2,
      center.dy + radius * math.sin(angle) - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
