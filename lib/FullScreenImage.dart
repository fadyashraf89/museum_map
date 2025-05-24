import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io'; // Import for File.fromUri
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

import 'AllColors.dart'; // Assuming AllColors is accessible

class FullScreenImagePage extends StatefulWidget {
  final String imagePath; // This can now be a local file path or an asset path
  final String hallNumber;
  final int imageIndex;
  final List<Map<String, dynamic>> artifacts;
  final bool isDataAvailable; // New flag to indicate if JSON data is available
  final String? scannedArtifactName; // Added as a named parameter
  final String? audioPath; // New: Path to the audio asset for this artifact

  const FullScreenImagePage({
    super.key,
    required this.imagePath,
    required this.hallNumber,
    required this.imageIndex,
    required this.artifacts,
    this.isDataAvailable = true,
    this.scannedArtifactName, // Now a named parameter
    this.audioPath, // New named parameter
  });

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  double _bottomSheetHeight = 200.0; // Initial height
  final double _minHeight = 200.0;
  double _maxHeight = 0.0; // Will be set in initState
  final double _initialSnapHeight = 0.5; //snap at 50% of max height
  bool _isBottomSheetDismissed = false;

  // Audio player variables
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped; // Track player state
  bool _audioAvailable = false; // Flag to check if audioPath is provided

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();

    // Check if an audio path is provided from the widget (which comes from JSON)
    if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
      _audioAvailable = true;
    } else {
      // If no specific audioPath is provided via widget.audioPath (i.e., from JSON),
      // we still assume placeholder audio is available for demonstration.
      // In a production app without placeholder, you'd set _audioAvailable = false here.
      _audioAvailable = true; // Set to true to show controls, relying on placeholder
    }

    // Calculate max height based on image height and screen height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      _maxHeight = screenHeight * 0.8; // Example: 80% of screen height
      _bottomSheetHeight = _maxHeight * _initialSnapHeight;
      setState(() {}); //update initial height
    });
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    // Use the provided audioPath from the widget (which comes from JSON)
    // If widget.audioPath is null or empty, it falls back to the placeholder.
    final audioSource = widget.audioPath != null && widget.audioPath!.isNotEmpty
        ? AssetSource(widget.audioPath!.replaceFirst('assets/', '')) // Correctly uses JSON path
        : AssetSource('audio/voice1.mp3'); // Fallback placeholder audio

    try {
      await _audioPlayer.play(audioSource);
      if (mounted) {
        setState(() {
          _playerState = PlayerState.playing;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio. Check asset path: ${widget.audioPath ?? 'placeholder'}')),
        );
        setState(() {
          _playerState = PlayerState.stopped;
        });
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    if (mounted) {
      setState(() {
        _playerState = PlayerState.paused;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _playerState = PlayerState.stopped;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Release audio player resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBottomSheetDismissed) {
      return const SizedBox(); // Return an empty widget if dismissed.
    }
    return Scaffold(
      body: Stack(
        children: [
          // Conditionally display image from asset or file
          widget.imagePath.startsWith('assets/')
              ? Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load asset image',
                      style: GoogleFonts.poppins().copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          )
              : Image.file(
            File(widget.imagePath), // Use File.fromUri if it's a file path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load scanned image',
                      style: GoogleFonts.poppins().copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            // Back button
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: AllColors.primaryColor, // Semi-transparent background
                  borderRadius:
                  BorderRadius.circular(20), // Rounded corners
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
          Align(
            // Bottom Sheet
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _bottomSheetHeight -= details.primaryDelta!;
                  _bottomSheetHeight = _bottomSheetHeight.clamp(
                    _minHeight,
                    _maxHeight,
                  ); //keep it between min and max
                });
              },
              onVerticalDragEnd: (details) {
                //snap to nearest height
                if (_bottomSheetHeight < _maxHeight / 4) {
                  setState(() {
                    _bottomSheetHeight =
                        _minHeight; // Dismiss if dragged below 1/4 of max
                    _isBottomSheetDismissed =
                    true; // Set the dismissed flag.
                  });
                  Navigator.of(context).pop(); //also pop
                } else if (_bottomSheetHeight < _maxHeight * 0.75) {
                  setState(() {
                    _bottomSheetHeight =
                        _maxHeight *
                            _initialSnapHeight; // Snap to 50% on medium drag
                  });
                } else {
                  setState(() {
                    _bottomSheetHeight =
                        _maxHeight; // Expand to full height on large drag
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                height: _bottomSheetHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AllColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: _buildBottomSheetContent(
                  context,
                  widget.hallNumber,
                  widget.imageIndex,
                  widget.artifacts,
                  widget.isDataAvailable, // Pass the new flag
                  widget.scannedArtifactName, // Pass the scanned name
                ), // Pass context here
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(
      BuildContext context,
      String hallNumber,
      int imageIndex,
      List<Map<String, dynamic>> artifacts,
      bool isDataAvailable, // Receive the new flag
      String? scannedArtifactName, // Receive the scanned name
      ) {
    // Conditionally get artifact data or provide a default empty map
    final artifact = (isDataAvailable && imageIndex >= 0 && imageIndex < artifacts.length)
        ? artifacts[imageIndex]
        : <String, dynamic>{}; // Empty map if no data or index out of bounds

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                // Draggable indicator
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isDataAvailable // Only show artifact name from JSON if data is available
                      ? Text(
                    '${artifact['Artifact Name'] ?? 'N/A'}', // Null check for Artifact Name
                    style: GoogleFonts.merriweather(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AllColors.primaryColor,
                    ),
                  )
                      : Text(
                    '${scannedArtifactName?.isNotEmpty == true && scannedArtifactName != 'Unknown Artifact' ? scannedArtifactName : 'Scanned Artifact'}',
                    style: GoogleFonts.merriweather(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AllColors.primaryColor,
                    ),
                  ),
                ),
                if (_audioAvailable) // Show speaker icon only if audio is potentially available
                  IconButton(
                    icon: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: AllColors.primaryColor,
                      size: 36,
                    ),
                    onPressed: () {
                      // if (_playerState == PlayerState.playing) {
                      //   _pauseAudio();
                      // } else {
                      //   _playAudio();
                      // }
                    },
                    tooltip: _playerState == PlayerState.playing ? 'Pause Audio' : 'Play Audio',
                  ),
                if (_audioAvailable && _playerState != PlayerState.stopped) // Show stop button only if playing or paused
                  IconButton(
                    icon: Icon(
                      Icons.stop_circle,
                      color: AllColors.primaryColor,
                      size: 36,
                    ),
                    onPressed: _stopAudio,
                    tooltip: 'Stop Audio',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isDataAvailable) ...[
              // Only show details if data is available
              _buildDetailRow('Inventory Number', artifact['Inventory Number']?.toString() ?? 'N/A'),
              _buildDetailRow('Description', artifact['Description']?.toString() ?? 'N/A'),
              _buildDetailRow('Material', artifact['Material']?.toString() ?? 'N/A'),
              if (artifact['Length'] != null)
                _buildDetailRow('Length', artifact['Length']?.toString() ?? 'N/A'),
              if (artifact['Width'] != null)
                _buildDetailRow('Width', artifact['Width']?.toString() ?? 'N/A'),
              if (artifact['Height'] != null)
                _buildDetailRow('Height', artifact['Height']?.toString() ?? 'N/A'),
              if (artifact['Provenance'] != null)
                _buildDetailRow('Provenance', artifact['Provenance']?.toString() ?? 'N/A'),
              if (artifact['Dating'] != null)
                _buildDetailRow('Dating', artifact['Dating']?.toString() ?? 'N/A'),
            ] else ...[
              Text(
                'No detailed information found for this artifact in the museum collection. This might be a new discovery!',
                style: GoogleFonts.poppins().copyWith(
                  fontSize: 16,
                  color: AllColors.bodytext,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // Increased vertical padding for better spacing
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            // Using Google Fonts for consistent style
            fontSize: 16, // Increased font size for better readability
            color: Colors.black87, // Slightly darker text for better contrast
            height: 1.5, // Added line height for improved spacing
          ),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w900, // Use semi-bold for labels
                color: AllColors.primaryColor, // Keep label color consistent
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}