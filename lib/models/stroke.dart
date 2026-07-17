import 'package:flutter/material.dart';

class Stroke {
  final List<Offset> points;
  final String colorHex;
  final double width;
  final bool isEraser;

  Stroke({
    required this.points,
    required this.colorHex,
    required this.width,
    required this.isEraser,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'colorHex': colorHex,
      'width': width,
      'isEraser': isEraser,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    var pointsList = json['points'] as List;
    List<Offset> parsedPoints = pointsList.map((p) {
      return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
    }).toList();

    return Stroke(
      points: parsedPoints,
      colorHex: json['colorHex'] as String,
      width: (json['width'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
