import 'dart:math';
import 'package:flutter/material.dart';

import 'Room.dart';

class SecondFloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Offset> pathPoints;
  final double scale;
  final Offset offset;
  final Room? startRoom;
  final Room? endRoom;

  SecondFloorPlanPainter({
    required this.rooms,
    required this.pathPoints,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.startRoom,
    this.endRoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0 / scale
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw rooms - EXACTLY like first floor
    for (final room in rooms.where((r) => r.label != 'empty' && r.label != 'empty2')) {
      final scaledRect = Rect.fromLTWH(
        room.left,
        room.top,
        room.width,
        room.height,
      );
      final roundedRect = RRect.fromRectAndRadius(
        scaledRect,
        Radius.circular(8.0 / scale), // Same rounded corners
      );

      // Fill room with same color as first floor
      final fillPaint = Paint()..color = const Color(0xFFF4E5D1);
      canvas.drawRRect(roundedRect, fillPaint);

      // Draw room border - identical to first floor
      canvas.drawRRect(roundedRect, borderPaint);

      // Draw room label - same style as first floor
      textPainter.text = TextSpan(
        text: room.displayName,
        style: TextStyle(
          color: Colors.black,
          fontSize: 12 / scale,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout(minWidth: 0, maxWidth: room.width);
      final textX = room.left + (room.width - textPainter.width) / 2;
      final textY = room.top + (room.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Draw empty spaces with identical stippling effect
    for (final room in rooms.where((r) => r.label == 'empty' || r.label == 'empty2')) {
      final emptySpaceRect = Rect.fromLTWH(
        room.left,
        room.top,
        room.width,
        room.height,
      );

      // Same fill color as first floor
      final emptySpacePaint = Paint()..color = Colors.grey[200]!;
      canvas.drawRect(emptySpaceRect, emptySpacePaint);

      // Same border
      canvas.drawRect(emptySpaceRect, borderPaint);

      // Identical stippling effect
      final stipplePaint = Paint()
        ..color = Colors.grey[600]!
        ..style = PaintingStyle.fill;
      const double stippleDensity = 0.008;
      final numStipplePoints =
      (room.width * room.height * stippleDensity).round().clamp(5, 100);

      final random = Random();
      for (int i = 0; i < numStipplePoints; i++) {
        final x = room.left + random.nextDouble() * room.width;
        final y = room.top + random.nextDouble() * room.height;
        canvas.drawCircle(Offset(x, y), 1.0 / scale, stipplePaint);
      }
    }

    // Draw corridor with same style
    _drawCorridor(canvas);

    // Draw doors with identical styling
    _drawDoors(canvas);

    // Draw path - EXACTLY like first floor
    if (startRoom != null && endRoom != null && pathPoints.isNotEmpty) {
      final pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * scale // Same as first floor
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF81C784); // Same green color

      // Draw main path line
      final path = Path();
      path.moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (int i = 1; i < pathPoints.length; i++) {
        path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      canvas.drawPath(path, pathPaint);

      // Draw direction indicators - same as first floor
      final arrowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF81C784);

      for (int i = 1; i < pathPoints.length; i++) {
        final start = pathPoints[i - 1];
        final end = pathPoints[i];
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);

        // Same arrow head style
        final arrowSize = 8.0 / scale;
        final pathArrow = Path();
        pathArrow.moveTo(end.dx, end.dy);
        pathArrow.lineTo(
          end.dx - arrowSize * cos(angle - pi / 6),
          end.dy - arrowSize * sin(angle - pi / 6),
        );
        pathArrow.lineTo(
          end.dx - arrowSize * cos(angle + pi / 6),
          end.dy - arrowSize * sin(angle + pi / 6),
        );
        pathArrow.close();
        canvas.drawPath(pathArrow, arrowPaint);
      }

      // Draw start and end markers - identical to first floor
      const double markerSize = 20.0;
      final startPainter = TextPainter(textDirection: TextDirection.ltr);
      startPainter.text = TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: markerSize / scale,
          color: Colors.green[700],
        ),
      );
      startPainter.layout();
      startPainter.paint(
        canvas,
        Offset(
          pathPoints.first.dx - startPainter.width / 2,
          pathPoints.first.dy - startPainter.height / 2,
        ),
      );

      final endPainter = TextPainter(textDirection: TextDirection.ltr);
      endPainter.text = TextSpan(
        text: String.fromCharCode(Icons.flag.codePoint),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: markerSize / scale,
          color: Colors.red[700],
        ),
      );
      endPainter.layout();
      endPainter.paint(
        canvas,
        Offset(
          pathPoints.last.dx - endPainter.width / 2,
          pathPoints.last.dy - endPainter.height / 2,
        ),
      );
    }

    canvas.restore();
  }

  void _drawCorridor(Canvas canvas) {
    final corridor = rooms.firstWhere((r) => r.label == 'corridor');
    final corridorPaint = Paint()
      ..color = Colors.grey[300]! // Same as first floor's open area
      ..style = PaintingStyle.fill;
    final corridorRect = corridor.rect;
    canvas.drawRect(corridorRect, corridorPaint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0 / scale
      ..style = PaintingStyle.stroke;
    canvas.drawRect(corridorRect, borderPaint);

    // Draw corridor label - same style as rooms
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: corridor.displayName,
        style: TextStyle(
          color: Colors.black,
          fontSize: 12 / scale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: corridor.width);
    final textX = corridor.left + (corridor.width - textPainter.width) / 2;
    final textY = corridor.top + (corridor.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  void _drawDoors(Canvas canvas) {
    final doorPaint = Paint()
      ..color = const Color(0xFFF4E5D1) // Same as first floor
      ..strokeWidth = 5.0 / scale
      ..style = PaintingStyle.stroke;

    // Find all adjacent room pairs
    for (final room in rooms.where((r) => r.label != 'empty' && r.label != 'empty2')) {
      for (final otherRoom in _findAdjacentRooms(room)) {

        if (otherRoom.label == 'empty' ||
            otherRoom.label == 'empty2' ||
            otherRoom.left < room.left ||
            otherRoom.top < room.top) {
          continue;
        }

        // Horizontal adjacency (left/right)
        if (room.left + room.width == otherRoom.left ||
            otherRoom.left + otherRoom.width == room.left) {
          final double overlapStart = max(room.top, otherRoom.top);
          final double overlapEnd =
          min(room.top + room.height, otherRoom.top + otherRoom.height);
          final double doorY = overlapStart + (overlapEnd - overlapStart) / 2;
          final double doorX =
          min(room.left + room.width, otherRoom.left + otherRoom.width);

          // Draw vertical door line - same as first floor
          final doorLength = 12.0 / scale;
          canvas.drawLine(
            Offset(doorX, doorY - doorLength / 2),
            Offset(doorX, doorY + doorLength / 2),
            doorPaint,
          );
        }
        // Vertical adjacency (top/bottom)
        else if (room.top == otherRoom.top + otherRoom.height ||
            otherRoom.top == room.top + room.height) {
          final double overlapStart = max(room.left, otherRoom.left);
          final double overlapEnd =
          min(room.left + room.width, otherRoom.left + otherRoom.width);
          final double doorX = overlapStart + (overlapEnd - overlapStart) / 2;
          final double doorY =
          min(room.top + room.height, otherRoom.top + otherRoom.height);

          // Draw horizontal door line - same as first floor
          final doorLength = 12.0 / scale;
          canvas.drawLine(
            Offset(doorX - doorLength / 2, doorY),
            Offset(doorX + doorLength / 2, doorY),
            doorPaint,
          );
        }
      }
    }
    _drawAdditionalDoors(canvas);
  }

  void _drawAdditionalDoors(Canvas canvas) {
    final doorPaint = Paint()
      ..color = const Color(0xFFF4E5D1) // Same as first floor
      ..strokeWidth = 7.0 / scale
      ..style = PaintingStyle.stroke;

    // Helper functions with same implementation as first floor
    void drawHorizontalDoor(double x, double y, double length) {
      canvas.drawLine(
        Offset(x - length / 2, y),
        Offset(x + length / 2, y),
        doorPaint,
      );
    }

    void drawVerticalDoor(double x, double y, double length) {
      canvas.drawLine(
        Offset(x, y - length / 2),
        Offset(x, y + length / 2),
        doorPaint,
      );
    }

    final doorLength = 12.0 / scale;

    // Get all relevant rooms
    final room10 = rooms.firstWhere((room) => room.label == '10');
    final room11 = rooms.firstWhere((room) => room.label == '11');
    final room17 = rooms.firstWhere((room) => room.label == '17');
    final room18 = rooms.firstWhere((room) => room.label == '18');
    final room19 = rooms.firstWhere((room) => room.label == '19');
    final room20 = rooms.firstWhere((room) => room.label == '20');
    final room21 = rooms.firstWhere((room) => room.label == '21');
    final room22 = rooms.firstWhere((room) => room.label == '22');
    final room23 = rooms.firstWhere((room) => room.label == '23');
    final room26 = rooms.firstWhere((room) => room.label == '26');
    final corridor = rooms.firstWhere((room) => room.label == 'corridor');
    final room24 = rooms.firstWhere((room) => room.label == '24');
    final room13 = rooms.firstWhere((room) => room.label == '13');
    final room14 = rooms.firstWhere((room) => room.label == '14');

    // Draw all special doors with same style as first floor
    double door23_24X = room23.left + room23.width / 2;
    double door23_24Y = room23.top;
    drawHorizontalDoor(door23_24X, door23_24Y, doorLength);

    double door13_14X = room13.left + room13.width / 2;
    double door13_14Y = room13.top;
    drawHorizontalDoor(door13_14X, door13_14Y, doorLength);


    double door10_11X = room11.left + room11.width;
    double door10_11Y = room11.top + room11.height / 2;
    drawVerticalDoor(door10_11X, door10_11Y, doorLength);

    double door17CorridorX = room17.left + room17.width / 2;
    double door17CorridorY = corridor.top + corridor.height;
    drawHorizontalDoor(door17CorridorX, door17CorridorY, doorLength);

    double door18CorridorX = room18.left;
    double door18CorridorY = corridor.top - 20 + corridor.height;
    drawVerticalDoor(door18CorridorX, door18CorridorY, doorLength + 20);


    double door18_19X = room18.left + (room18.width / 2);
    double door18_19Y = room18.top + room18.height;
    drawHorizontalDoor(door18_19X, door18_19Y, doorLength);

    double door19_20X = room19.left + room19.width / 2;
    double door19_20Y = room19.top + room19.height;
    drawHorizontalDoor(door19_20X, door19_20Y, doorLength);

    double door20_21X = room20.left + room20.width;
    double door20_21Y = room20.top + room20.height / 2;
    drawVerticalDoor(door20_21X, door20_21Y, doorLength);

    double door21_22X = room21.left + room21.width / 2;
    double door21_22Y = room21.top;
    drawHorizontalDoor(door21_22X, door21_22Y, doorLength);

    double door22_23X = room22.left + room22.width / 2;
    double door22_23Y = room22.top;
    drawHorizontalDoor(door22_23X, door22_23Y, doorLength);
  }

  List<Room> _findAdjacentRooms(Room room) {
    List<Room> adjacentRooms = [];
    for (var otherRoom in rooms) {
      if (otherRoom == room) continue;

      // Check for horizontal adjacency
      if ((room.left == otherRoom.left + otherRoom.width ||
          room.left + room.width == otherRoom.left) &&
          (room.top < otherRoom.top + otherRoom.height &&
              room.top + room.height > otherRoom.top)) {
        adjacentRooms.add(otherRoom);
      }
      // Check for vertical adjacency
      else if ((room.top == otherRoom.top + otherRoom.height ||
          otherRoom.top + room.height == otherRoom.top) &&
          (room.left < otherRoom.left + otherRoom.width &&
              room.left + room.width > otherRoom.left)) {
        adjacentRooms.add(otherRoom);
      }
    }
    return adjacentRooms;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is SecondFloorPlanPainter) {
      return rooms != oldDelegate.rooms ||
          pathPoints != oldDelegate.pathPoints ||
          scale != oldDelegate.scale ||
          offset != oldDelegate.offset ||
          startRoom != oldDelegate.startRoom ||
          endRoom != oldDelegate.endRoom;
    }
    return true;
  }
}