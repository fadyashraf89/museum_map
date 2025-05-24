import 'dart:math';
import 'package:flutter/material.dart';
// Ensure sizer is correctly configured, but not directly used in this code

import 'AllColors.dart'; // Ensure these are correctly defined
import 'HallCollectionScreen.dart';
import 'PriorityQueue.dart'; // Ensure this is correctly implemented
import 'Room.dart'; // Ensure this is correctly defined
import 'SecondFloorPainter.dart'; // Ensure this is correctly implemented
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts for text styles

class SecondFloorPlanSketch extends StatefulWidget {
  const SecondFloorPlanSketch({super.key});

  @override
  _SecondFloorPlanSketchState createState() => _SecondFloorPlanSketchState();
}

class _SecondFloorPlanSketchState extends State<SecondFloorPlanSketch> {
  late List<Room> _rooms;
  final List<List<String>> _doorConnections = [
    ['10', '11'],
    ['10', '17'],
    ['11', '12'],
    ['12', '13'],
    ['13', '14'],
    ['14', '15'],
    ['15', '16'],
    ['17', '10'],
    ['17', 'corridor'],
    ['18', 'corridor'],
    ['18', '19'],
    ['19', '20'],
    ['20', '21'],
    ['21', '22'],
    ['22', '23'],
    ['23', '24'],
    ['24', '25'],
    ['16', '17'],
    ['17', '16'],
    ['25', '26'],
    ['11', '10'],
    ['12', '11'],
    ['13', '12'],
    ['14', '13'],
    ['15', '14'],
    ['16', '15'],
    ['corridor', '17'],
    ['corridor', '18'],
    ['19', '18'],
    ['20', '19'],
    ['21', '20'],
    ['22', '21'],
    ['23', '22'],
    ['24', '23'],
    ['25', '24'],
    ['26', '25'],
  ];
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
    const double contentWidth = 800.0;
    const double contentHeight = 1200.0;

    final scaleX = screenWidth / contentWidth;
    final scaleY = screenHeight / contentHeight;
    _scale = min(scaleX, scaleY) * 0.8;

    _offset = Offset(
      (screenWidth - contentWidth * _scale) + 50,
      (screenHeight - contentHeight * _scale) / 2,
    );
    if (mounted) {
      // check if the widget is mounted before calling setState
      setState(() {});
    }
  }

  void _initializeRooms() {
    const double roomWidth = 60.0;
    const double roomHeight = 60.0;
    const double spacing = 0.0;
    const double corridorWidth = 180;
    const double corridorHeight = 50.0;
    const double startX = -150.0;
    const double startY = -100.0;

    _rooms = [
      // Top Row (Building 2) - Adjusted
      Room(
        left: startX + 440,
        top: startY + corridorHeight - roomHeight - 85,
        width: roomWidth,
        height: 2.3 * roomHeight + spacing + 15,
        label: '26',
        displayName: '26',
      ),
      Room(
        left: startX + 440 + roomWidth + spacing,
        top: startY - 95,
        width: roomWidth * 2,
        height: roomHeight,
        label: '25',
        displayName: '25',
      ),
      Room(
        left: startX + 440 + 3 * (roomWidth + spacing),
        top: startY - 95,
        width: roomWidth,
        height: roomHeight,
        label: '24',
        displayName: '24',
      ),
      Room(
        left: startX + 500 + 2 * (roomWidth + spacing),
        top: startY + roomHeight + spacing - 95,
        width: roomWidth,
        height: 3 * roomHeight + spacing,
        label: '23',
        displayName: '23',
      ),
      // Corridor between buildings (Moved)
      Room(
        left: startX + 4 * (roomWidth + spacing),
        top: startY + roomHeight + spacing,
        width: corridorWidth,
        height: corridorHeight,
        label: 'corridor',
        displayName: 'Corridor',
        color: Colors.grey[300]!,
      ),
      // Middle Row (Building 1)
      Room(
        left: startX,
        top: startY + roomHeight + spacing + corridorHeight + spacing,
        width: roomWidth,
        height: roomHeight,
        label: '14',
        displayName: '14',
      ),
      Room(
        left: startX + roomWidth + spacing,
        top: startY + roomHeight + spacing + corridorHeight + spacing,
        width: roomWidth,
        height: roomHeight,
        label: '15',
        displayName: '15',
      ),
      Room(
        left: startX + 2 * (roomWidth + spacing),
        top: startY + roomHeight + spacing + corridorHeight + spacing,
        width: 2 * roomWidth + spacing,
        height: roomHeight,
        label: '16',
        displayName: '16',
      ),
      Room(
        left: startX + 4 * (roomWidth + spacing),
        top: startY + roomHeight + spacing + corridorHeight + spacing,
        width: roomWidth,
        height: roomHeight,
        label: '17',
        displayName: '17',
      ),
      Room(
        left: startX + 7 * (roomWidth + spacing),
        top: startY + roomHeight + spacing + corridorHeight + spacing - 50,
        width: roomWidth + 20,
        height: 2.3 * roomHeight,
        label: '18',
        displayName: '18',
      ),
      // Room 19 (added back)
      Room(
        left: startX + 420,
        top: startY +
            3 * (roomHeight + spacing) +
            corridorHeight -
            28 +
            spacing,
        width: roomWidth + 20,
        height: roomHeight * 2.5 - 4,
        label: '19',
        displayName: '19',
      ),
      // Empty Spaces - Adjusted for new layout
      Room(
        left: startX + 1 * (roomWidth + spacing),
        top: startY + 2 * (roomHeight + spacing) + corridorHeight + spacing,
        width: 3 * roomWidth + spacing,
        height: roomHeight,
        label: 'empty',
        displayName: 'Empty Space',
        color: Colors.grey[400]!,
      ),
      Room(
        left: startX + 440 + roomWidth + spacing,
        top: startY + (roomHeight / 3) - 50,
        width: roomWidth + 60 + spacing,
        height: 6 * roomHeight + 15,
        label: 'empty2',
        displayName: 'Empty Space',
        color: Colors.grey[400]!,
      ),
      // Bottom Row (Building 1) - Adjusted for new layout
      Room(
        left: startX,
        top: startY + 2 * (roomHeight + spacing) + corridorHeight + spacing,
        width: roomWidth,
        height: 2 * roomHeight + spacing,
        label: '13',
        displayName: '13',
      ),
      Room(
        left: startX + roomWidth + spacing,
        top: startY +
            2 * (roomHeight + spacing) +
            corridorHeight +
            spacing +
            roomHeight +
            spacing,
        width: roomWidth,
        height: roomHeight,
        label: '12',
        displayName: '12',
      ),
      Room(
        left: startX + 2 * (roomWidth + spacing),
        top: startY +
            2 * (roomHeight + spacing) +
            corridorHeight +
            spacing +
            roomHeight +
            spacing,
        width: 2 * roomWidth + spacing,
        height: roomHeight,
        label: '11',
        displayName: '11',
      ),
      Room(
        left: startX + 4 * (roomWidth + spacing),
        top: startY + 2 * (roomHeight + spacing) + corridorHeight + spacing,
        width: roomWidth,
        height: 2 * roomHeight + spacing,
        label: '10',
        displayName: '10',
      ),
      // Bottom Row (Building 2) - Adjusted
      Room(
        left: startX + 560 + roomWidth + spacing,
        top: startY + 2.5 * (roomHeight + spacing),
        width: roomWidth,
        height: roomHeight + 45,
        label: '22',
        displayName: '22',
      ),
      Room(
        left: startX + 500 + 2 * (roomWidth + spacing),
        top: startY + 3.5 * (roomHeight + spacing) + corridorHeight + spacing,
        width: roomWidth,
        height: 2.5 * roomHeight + spacing,
        label: '21',
        displayName: '21',
      ),
      Room(
        left: startX + 420,
        top: startY + 5 * (roomHeight + spacing) + corridorHeight + spacing,
        width: 3.3 * roomWidth + 2 * spacing,
        height: roomHeight,
        label: '20',
        displayName: '20',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Exclude corridor from sortedRooms
    List<Room> sortedRooms = List.from(_rooms)
      ..removeWhere((room) =>
      room.label == 'empty' ||
          room.label == 'empty2' ||
          room.label == 'corridor')
      ..sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));

    return Scaffold(
      backgroundColor: AllColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Upper Level',
          style: GoogleFonts.ebGaramond(
            color: AllColors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 21.0,
          ),
        ),
        backgroundColor: AllColors.primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/background.png"), // Ensure this path is correct
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
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AllColors.third,
                      ),
                      value: _startRoom,
                      hint: Text("Select Start",
                          style: GoogleFonts.poppins(
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
                          child: Text("Hall ${room.displayName}",
                              style: GoogleFonts.poppins(
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
                    child: DropdownButtonFormField<Room>(
                      decoration: InputDecoration(
                        labelText: 'Destination Hall',
                        labelStyle: GoogleFonts.poppins(
                          color: AllColors.bodytext,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AllColors.third,
                      ),
                      value: _endRoom,
                      hint: Text("Select Destination",
                          style: GoogleFonts.poppins(
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
                          child: Text("Hall ${room.displayName}",
                              style: GoogleFonts.poppins(
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AllColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Navigate To Ground Floor",
                          style: GoogleFonts.poppins(
                            color: AllColors.secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ),
                  ),
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
                      backgroundColor: AllColors
                          .primaryColor, // Or any color you prefer
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Clear Navigation",
                        style: GoogleFonts.poppins(
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
                    // check if the widget is mounted before calling setState
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
                          painter: SecondFloorPlanPainter(
                            // Ensure SecondFloorPainter is correctly implemented.
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
                              final RenderBox? renderBox = _overlayKey
                                  .currentContext
                                  ?.findRenderObject() as RenderBox?;
                              if (renderBox != null) {
                                final localPosition =
                                renderBox.globalToLocal(details.globalPosition);
                                final scaledPosition =
                                    (localPosition - _offset) / _scale;

                                for (final room in _rooms) {
                                  if (room.contains(scaledPosition)) {
                                    // Prevent taps on 'empty' or 'corridor' rooms
                                    if (room.label != 'empty' &&
                                        room.label != 'empty2') {
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

    // Initialize data structures
    Map<String, double> distances = {};
    Map<String, String?> previous = {};
    PriorityQueue<String> queue =
    PriorityQueue<String>((a, b) => distances[a]!.compareTo(distances[b]!));

    // Initialize distances
    for (var room in _rooms) {
      distances[room.label] = double.infinity;
    }
    distances[_startRoom!.label] = 0;
    queue.add(_startRoom!.label);

    while (!queue.isEmpty) {
      final currentRoomLabel = queue.remove();
      final currentRoom = _findRoomByLabel(currentRoomLabel);
      if (currentRoom == null) continue; // Safety check

      if (currentRoomLabel == _endRoom!.label) {
        break; // Found the end room
      }

      final adjacentRooms =
      _findAdjacentRoomsWithDoors(currentRoom); // Use the new method

      for (var adjacentRoom in adjacentRooms) {
        double distance =
            distances[currentRoomLabel]! + _calculateDistance(currentRoom, adjacentRoom);
        if (distance < distances[adjacentRoom.label]!) {
          distances[adjacentRoom.label] = distance;
          previous[adjacentRoom.label] = currentRoomLabel;
          queue.add(adjacentRoom.label);
        }
      }
    }

    // Reconstruct path
    List<Offset> newPathPoints = [];
    String? currentLabel = _endRoom!.label;
    while (currentLabel != null) {
      final currentRoom = _findRoomByLabel(currentLabel);
      if (currentRoom != null) {
        newPathPoints.insert(0, Offset(currentRoom.center.x, currentRoom.center.y));
      }
      currentLabel = previous[currentLabel];
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

  // Helper method to check for door connections between two rooms
  bool _hasDoorBetween(Room room1, Room room2) {
    final room1Label = room1.label;
    final room2Label = room2.label;

    // Check if the connection exists in either order
    for (final connection in _doorConnections) {
      if ((connection[0] == room1Label && connection[1] == room2Label) ||
          (connection[0] == room2Label && connection[1] == room1Label)) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(Room room1, Room room2) {
    return sqrt(pow(room2.center.x - room1.center.x, 2) +
        pow(room2.center.y - room1.center.y, 2));
  }

  Room? _findRoomByLabel(String label) {
    for (var room in _rooms) {
      if (room.label == label) {
        return room;
      }
    }
    return null;
  }

  void _handleRoomTap(Room tappedRoom, BuildContext context) {
    // Prevent navigation if the tapped room is an "empty" or "corridor" room
    if (tappedRoom.label == 'empty' || tappedRoom.label == 'empty2') {
      return; // Do nothing if it's an unclickable room
    }
    // Show both room info and navigate to collection
    // Removed _showRoomInfo as per typical usage, keeping _navigateToHallCollection
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


  List<Room> _findAdjacentRoomsWithDoors(Room room) {
    List<Room> adjacentRooms = [];
    for (var otherRoom in _rooms) {
      if (otherRoom == room) continue;

      // Check for specific door connections
      if (_hasDoorBetween(room, otherRoom)) {
        adjacentRooms.add(otherRoom);
      }
    }
    return adjacentRooms;
  }
}
