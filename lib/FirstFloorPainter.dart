import 'dart:math';
import 'package:flutter/material.dart';

import 'Room.dart';

class FirstFloorPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Offset> pathPoints;
  final double scale;
  final Offset offset;
  final Room? startRoom;
  final Room? endRoom;

  FirstFloorPainter({
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

    // Draw rooms
    for (final room in rooms) {
      final scaledRect = Rect.fromLTWH(
        room.left,
        room.top,
        room.width,
        room.height,
      );
      final roundedRect = RRect.fromRectAndRadius(
        scaledRect, Radius.circular(8.0 / scale), // More rounded corners
      );

      // Fill room with color
      final fillPaint = Paint()..color = const Color(0xFFF4E5D1); //AllColors.third;
      canvas.drawRRect(roundedRect, fillPaint);

      // Draw room border
      canvas.drawRRect(roundedRect, borderPaint);

      // Draw room label (displayName)
      textPainter.text = TextSpan(
        text: room.displayName,
        style: TextStyle(
            color: Colors.black,
            fontSize: 12 / scale, // Slightly smaller font
            fontWeight: FontWeight.w500), // Medium font weight
      );
      textPainter.layout(minWidth: 0, maxWidth: room.width);
      final textX = room.left + (room.width - textPainter.width) / 2;
      final textY = room.top + (room.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Draw open area (rectangle with stippling)
    final openAreaLeft = rooms[0].left + rooms[0].width;
    final openAreaRight = rooms[3].left;
    final openAreaTop = rooms[0].top + rooms[0].height;
    final openAreaBottom = rooms[6].top;
    final openAreaRect =
    Rect.fromLTRB(openAreaLeft, openAreaTop, openAreaRight, openAreaBottom);

    // Fill open area
    final openAreaFillPaint = Paint()..color = Colors.grey[200]!; //Colors.grey[200]!;
    canvas.drawRect(openAreaRect, openAreaFillPaint);

    // Draw border
    canvas.drawRect(openAreaRect, borderPaint);

    // Draw stippling effect (more subtle)
    final stipplePaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;
    const double stippleDensity = 0.008; // Adjust for density
    final numStipplePoints =
    (openAreaRect.width * openAreaRect.height * stippleDensity)
        .round()
        .clamp(5, 100); // At least 5, at most 100

    final random = Random();
    for (int i = 0; i < numStipplePoints; i++) {
      final x = openAreaLeft + random.nextDouble() * openAreaRect.width;
      final y = openAreaTop + random.nextDouble() * openAreaRect.height;
      canvas.drawCircle(Offset(x, y), 1.0 / scale, stipplePaint);
    }

    // Draw path
    if (startRoom != null && endRoom != null && pathPoints.isNotEmpty) {
      final pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * scale //6.0 / scale
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF81C784); //Colors.blue[700]!; //AllColors.secondaryColor

      // Draw main path line
      final path = Path();
      path.moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (int i = 1; i < pathPoints.length; i++) {
        path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      canvas.drawPath(path, pathPaint);

      // Draw direction indicators
      final arrowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color =  const Color(0xFF81C784); //Colors.blue[700]!;

      for (int i = 1; i < pathPoints.length; i++) {
        final start = pathPoints[i - 1];
        final end = pathPoints[i];
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);

        // Draw arrow head
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

      // Draw start and end markers
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
          Offset(pathPoints.first.dx - startPainter.width / 2,
              pathPoints.first.dy - startPainter.height / 2));

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
          Offset(pathPoints.last.dx - endPainter.width / 2,
              pathPoints.last.dy - endPainter.height / 2));
    }
    _drawDoors(canvas);

    canvas.restore();
  }

  void _drawDoors(Canvas canvas) {
    final doorPaint = Paint()
      ..color = Color(0xFFF4E5D1)
      ..strokeWidth = 5.0 / scale
      ..style = PaintingStyle.stroke;

    // Draw doors between rooms (only between rooms that should be connected)
    for (int i = 0; i < rooms.length; i++) {
      for (int j = i + 1; j < rooms.length; j++) {
        final room1 = rooms[i];
        final room2 = rooms[j];

        // Skip connection between 2 and 9
        if ((room1.label == '2' && room2.label == '9') ||
            (room1.label == '9' && room2.label == '2')) {
          continue;
        }

        // Calculate overlapping area for adjacency
        final double xOverlap =
            min(room1.left + room1.width, room2.left + room2.width) -
                max(room1.left, room2.left);
        final double yOverlap =
            min(room1.top + room1.height, room2.top + room2.height) -
                max(room1.top, room2.top);

        // Horizontal adjacency (left/right)
        if ((room1.left + room1.width == room2.left ||
            room2.left + room2.width == room1.left) &&
            yOverlap > 0) {
          final double overlapStart = max(room1.top, room2.top);
          final double overlapEnd =
          min(room1.top + room1.height, room2.top + room2.height);
          final double doorY = overlapStart + (overlapEnd - overlapStart) / 2;
          final double doorX =
          min(room1.left + room1.width, room2.left + room2.width);

          // Draw door as a straight line (vertical line for horizontal adjacency)
          final doorLength = 12.0 / scale;
          canvas.drawLine(
            Offset(doorX, doorY - doorLength / 2),
            Offset(doorX, doorY + doorLength / 2),
            doorPaint,
          );
        }
        // Vertical adjacency (top/bottom)
        else if ((room1.top + room1.height == room2.top ||
            room2.top + room2.height == room1.top) &&
            xOverlap > 0) {
          final double overlapStart = max(room1.left, room2.left);
          final double overlapEnd =
          min(room1.left + room1.width, room2.left + room2.width);
          final double doorX = overlapStart + (overlapEnd - overlapStart) / 2;
          final double doorY =
          min(room1.top + room1.height, room2.top + room2.height);

          // Draw door as a straight line (horizontal line for vertical adjacency)
          final doorLength = 12.0 / scale;
          canvas.drawLine(
            Offset(doorX - doorLength / 2, doorY),
            Offset(doorX + doorLength / 2, doorY),
            doorPaint,
          );
        }
      }
    }

    // Add special doors
    final entranceDoorPaint = Paint()
      ..color = Color(0xFFF4E5D1)
      ..strokeWidth = 5.0 / scale
      ..style = PaintingStyle.stroke;

    // Entrance door to Room 1 (bottom side)
    final room1 = rooms.firstWhere((room) => room.label == '1');
    final entranceDoorLength = 15.0 / scale;
    canvas.drawLine(
      Offset(room1.left + room1.width / 2 - entranceDoorLength / 2,
          room1.top + room1.height),
      Offset(room1.left + room1.width / 2 + entranceDoorLength / 2,
          room1.top + room1.height),
      entranceDoorPaint,
    );

    // Door from Room 6 to hollow area (right side, raised position)
    final room6 = rooms.firstWhere((room) => room.label == '6');
    const raisedPosition6 = 0.4; // 40% from top instead of center
    canvas.drawLine(
      Offset(room6.left + room6.width,
          room6.top + room6.height * raisedPosition6 - entranceDoorLength / 2),
      Offset(room6.left + room6.width,
          room6.top + room6.height * raisedPosition6 + entranceDoorLength / 2),
      entranceDoorPaint,
    );

    // Door from Room 9 to hollow area (left side, raised position)
    final room9 = rooms.firstWhere((room) => room.label == '9');
    const raisedPosition9 = 0.4; // 40% from top instead of center
    canvas.drawLine(
      Offset(room9.left,
          room9.top + room9.height * raisedPosition9 - entranceDoorLength / 2),
      Offset(room9.left,
          room9.top + room9.height * raisedPosition9 + entranceDoorLength / 2),
      entranceDoorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is FirstFloorPainter) {
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

