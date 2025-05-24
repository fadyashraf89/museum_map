import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
class Room {
  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final String displayName;
  final Color color;

  Room({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    required this.displayName,
    this.color = Colors.white,
  });

  Rect get rect => Rect.fromLTWH(left, top, width, height);
  Vector2 get center => Vector2(left + width / 2, top + height / 2);

  bool contains(Offset point) {
    return point.dx >= left &&
        point.dx <= left + width &&
        point.dy >= top &&
        point.dy <= top + height;
  }
}