import 'package:flutter/material.dart';
import 'models/stroke.dart';

class CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;

  CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width;

      if (stroke.isEraser) {
        
        paint.color = const Color(0xff1A1C1E);
      } else {
        paint.color = HexColor.fromHex(stroke.colorHex);
      }

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
      } else {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
