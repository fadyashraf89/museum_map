import 'dart:math';
import 'package:flutter/material.dart';
// Ensure sizer is correctly configured, but not directly used in this code

import 'AllColors.dart'; // Ensure these are correctly defined
import 'HallCollectionScreen.dart';
import 'PriorityQueue.dart'; // Ensure this is correctly implemented
import 'Room.dart'; // Ensure this is correctly defined
import 'FirstFloorPainter.dart'; // Ensure this is correctly implemented
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts for text styles
import 'package:museum_map/second_floor.dart'; // Assuming this is the correct import for SecondFloorPlanSketch

class FirstFloorPlanSketch extends StatefulWidget {
  const FirstFloorPlanSketch({super.key});

  @override
  _FirstFloorPlanSketchState createState() =>
      _FirstFloorPlanSketchState();
}

class _FirstFloorPlanSketchState extends State<FirstFloorPlanSketch> {
  late List<Room> _rooms;
  List<Offset> _pathPoints = [];
  Room? _startRoom;
  Room? _endRoom;
  final GlobalKey _overlayKey = GlobalKey();
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  double _previousScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeRooms();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  void _centerView() {
    if (!mounted) return; // check if the widget is mounted before using context.

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const contentWidth = 650.0;
    const contentHeight = 1200.0;

    final scaleX = screenWidth / contentWidth;
    final scaleY = screenHeight / contentHeight;
    _scale = min(scaleX, scaleY) * 0.8;

    _offset = Offset(
      (screenWidth - contentWidth * _scale) / 2,
      (screenHeight - contentHeight * _scale) / 2,
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeRooms() {
    const double roomWidth = 80.0;
    const double roomHeight = 80.0;
    const double startX = -30.0;
    const double startY = -100.0;
    const double spacing = 0.0;
    const double room7And8Width = (2 * roomWidth + 2 * spacing) / 2;

    _rooms = [
      Room(
        left: startX,
        top: startY,
        width: roomWidth,
        height: roomHeight,
        label: '5',
        displayName: '5',
      ),
      Room(
        left: startX + roomWidth + spacing,
        top: startY,
        width: roomWidth,
        height: roomHeight,
        label: '4',
        displayName: '4',
      ),
      Room(
        left: startX + 2 * (roomWidth + spacing),
        top: startY,
        width: roomWidth + 100,
        height: roomHeight,
        label: '3',
        displayName: '3',
      ),
      Room(
        left: startX + 3 * (roomWidth + spacing) + 100,
        top: startY,
        width: roomWidth,
        height: roomHeight,
        label: '2',
        displayName: '2',
      ),
      Room(
        left: startX + 3 * (roomWidth + spacing) + 100,
        top: startY + roomHeight + spacing,
        width: roomWidth,
        height: roomHeight + 80,
        label: '9',
        displayName: '9',
      ),
      Room(
        left: startX,
        top: startY + roomHeight,
        width: roomWidth,
        height: roomHeight + 80,
        label: '6',
        displayName: '6',
      ),
      Room(
        left: startX + roomWidth + spacing,
        top: startY + 2 * (roomHeight + spacing),
        width: room7And8Width,
        height: roomHeight,
        label: '7',
        displayName: '7',
      ),
      Room(
        left: startX + roomWidth + spacing + room7And8Width + spacing,
        top: startY + 2 * (roomHeight + spacing),
        width: room7And8Width + 100,
        height: roomHeight,
        label: '8',
        displayName: '8',
      ),
      Room(
        left: startX + 4 * (roomWidth + spacing) + 100,
        top: startY,
        width: roomWidth + 100,
        height: roomHeight,
        label: '1',
        displayName: '1',
      ),
    ];
  }

  Room? _findRoomByLabel(String label) {
    for (var room in _rooms) {
      if (room.label == label) {
        return room;
      }
    }
    return null;
  }

  double _calculateDistance(Room room1, Room room2) {
    return sqrt(pow(room2.center.x - room1.center.x, 2) +
        pow(room2.center.y - room1.center.y, 2));
  }

  List<Room> _findAdjacentRooms(Room room) {
    List<Room> adjacentRooms = [];
    for (var otherRoom in _rooms) {
      if (otherRoom == room) continue;

      // Skip connection between 2 and 9
      if ((room.label == '2' && otherRoom.label == '9') ||
          (room.label == '9' && otherRoom.label == '2')) {
        continue;
      }

      // Check for horizontal adjacency with door
      if ((room.left == otherRoom.left + otherRoom.width ||
          room.left + room.width == otherRoom.left) &&
          (room.top < otherRoom.top + otherRoom.height &&
              room.top + room.height > otherRoom.top)) {
        adjacentRooms.add(otherRoom);
      }
      // Check for vertical adjacency with door
      else if ((room.top == otherRoom.top + otherRoom.height ||
          room.top + room.height == otherRoom.top) &&
          (room.left < otherRoom.left + otherRoom.width &&
              room.left + room.width > otherRoom.left)) {
        adjacentRooms.add(otherRoom);
      }
    }
    return adjacentRooms;
  }


  void _handleRoomTap(Room tappedRoom, BuildContext context) {
    // Prevent navigation if the tapped room is an "empty" or "corridor" room
    // Note: Based on current _initializeRooms, there are no explicitly labeled 'empty' or 'corridor' rooms on the first floor.
    // This check is added for future robustness if such rooms are introduced.
    if (tappedRoom.label == 'empty' || tappedRoom.label == 'empty2' || tappedRoom.label == 'corridor') {
      return; // Do nothing if it's an unclickable room
    }
    _navigateToHallCollection(tappedRoom.label, context);
  }

  void _navigateToHallCollection(String hallLabel, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HallCollectionScreen(hallNumber: hallLabel),
      ),
    );
  }

  void _calculatePath() {
    if (_startRoom == null || _endRoom == null) return;

    if (_startRoom == _endRoom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start and end cannot be the same room!')),
      );
      if (mounted) {
        setState(() => _pathPoints.clear());
      }
      return;
    }

    final Map<Room, double> distances = {};
    final Map<Room, Room?> previous = {};
    final PriorityQueue<Room> queue =
    PriorityQueue<Room>((a, b) => distances[a]!.compareTo(distances[b]!));

    for (var room in _rooms) {
      distances[room] = double.infinity;
      previous[room] = null;
    }
    distances[_startRoom!] = 0;
    queue.add(_startRoom!);

    while (!queue.isEmpty) {
      final currentRoom = queue.remove();

      if (currentRoom == _endRoom) break;

      for (var neighbor in _findAdjacentRooms(currentRoom)) {
        final distanceThroughCurrent =
            distances[currentRoom]! + _calculateDistance(currentRoom, neighbor);

        if (distanceThroughCurrent < distances[neighbor]!) {
          distances[neighbor] = distanceThroughCurrent;
          previous[neighbor] = currentRoom;
          queue.add(neighbor);
        }
      }
    }

    List<Offset> newPathPoints = [];
    Room? current = _endRoom;
    while (current != null) {
      newPathPoints.insert(0, Offset(current.center.x, current.center.y));
      current = previous[current];
    }

    if (newPathPoints.isNotEmpty) {
      if (mounted) {
        setState(() {
          _pathPoints = newPathPoints;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _pathPoints = [];
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No path found between these rooms!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Room> sortedRooms = List.from(_rooms);
    sortedRooms
        .sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));

    return Scaffold(
      backgroundColor: AllColors.background,
      appBar: AppBar(
        title:  Text(
          'Ground Level',
          style: GoogleFonts.ebGaramond(
            color: AllColors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 21.0,
          ),
        ),
        backgroundColor: AllColors.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,

          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: DropdownButtonFormField<Room>(
                      decoration: InputDecoration(
                        labelText: 'Start Hall',
                        labelStyle: GoogleFonts.poppins(
                          color: AllColors.bodytext,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                        filled: true,
                        fillColor: AllColors.third,
                      ),
                      value: _startRoom,
                      hint:  Text("Select Start", style: GoogleFonts.poppins(
                        color: AllColors.bodytext,
                        fontSize: 14,
                      )),
                      onChanged: (Room? newValue) {
                        if (mounted) {
                          setState(() {
                            _startRoom = newValue;
                            _pathPoints.clear();
                            _endRoom = null;
                          });
                        }
                      },
                      items: sortedRooms.map<DropdownMenuItem<Room>>((Room room) {
                        return DropdownMenuItem<Room>(
                          value: room,
                          child: Text("Hall ${room.displayName}", style: GoogleFonts.poppins(
                            color: AllColors.bodytext,
                            fontSize: 14,
                          )),
                        );
                      }).toList(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    child: DropdownButtonFormField<Room>(
                      decoration: InputDecoration(
                        labelText: 'Destination Hall',
                        labelStyle: GoogleFonts.poppins(
                          color: AllColors.bodytext,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                        filled: true,
                        fillColor: AllColors.third,
                      ),
                      value: _endRoom,
                      hint:  Text("Select Destination", style: GoogleFonts.poppins(
                        color: AllColors.bodytext,
                        fontSize: 14,
                      )),
                      onChanged: (Room? newValue) {
                        if (mounted) {
                          setState(() {
                            _endRoom = newValue;
                            if (newValue != null && _startRoom != null) {
                              _calculatePath();
                            }
                          });
                        }
                      },
                      items: sortedRooms.map<DropdownMenuItem<Room>>((Room room) {
                        return DropdownMenuItem<Room>(
                          value: room,
                          child: Text("Hall ${room.displayName}", style: GoogleFonts.poppins(
                            color: AllColors.bodytext,
                            fontSize: 14,
                          )),
                        );
                      }).toList(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AllColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SecondFloorPlanSketch()));
                        },
                        child:  Text("Navigate To Upper Floor", style: GoogleFonts.poppins(
                          color: AllColors.secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                      )),
                  const SizedBox(height: 20), // Added SizedBox for spacing
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startRoom = null;
                        _endRoom = null;
                        _pathPoints.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AllColors.primaryColor, // Or any color you prefer
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Clear Navigation", style: GoogleFonts.poppins(
                      color: AllColors.secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                constrained: true,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.3,
                maxScale: 4.0,
                onInteractionStart: (details) {
                  _previousOffset = _offset;
                  _previousScale = _scale;
                },
                onInteractionUpdate: (details) {
                  _scale = _previousScale * details.scale;
                  _offset = _previousOffset + details.focalPointDelta;
                },
                onInteractionEnd: (details) {
                  _scale = _scale;
                  _offset = _offset;
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Center(
                  child: SizedBox(
                    width: 700,
                    height: 600,
                    child: Stack(
                      key: _overlayKey,
                      children: [
                        CustomPaint(
                          painter: FirstFloorPainter(
                            rooms: _rooms,
                            pathPoints: _pathPoints,
                            scale: _scale,
                            offset: _offset,
                            startRoom: _startRoom,
                            endRoom: _endRoom,
                          ),
                          size: const Size(700, 600),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              final RenderBox? renderBox = // Added null safety
                              _overlayKey.currentContext?.findRenderObject() // Added null safety
                              as RenderBox?;
                              if (renderBox != null) { // Added null check
                                final localPosition =
                                renderBox.globalToLocal(details.globalPosition);
                                final scaledPosition =
                                    (localPosition - _offset) / _scale;

                                for (final room in _rooms) {
                                  if (room.contains(scaledPosition)) {
                                    // Prevent taps on 'empty' or 'corridor' rooms
                                    // (even if not currently defined for First Floor, for future robustness)
                                    if (room.label != 'empty' &&
                                        room.label != 'empty2' &&
                                        room.label != 'corridor') {
                                      _handleRoomTap(room, context);
                                    }
                                    break;
                                  }
                                }
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
