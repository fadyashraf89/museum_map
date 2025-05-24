import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

import 'AllColors.dart'; // Assuming AllColors.dart is present and unchanged
import 'FullScreenImage.dart'; // Import the FullScreenImagePage
import 'ScanHistoryScreen.dart'; // Import the new ScanHistoryScreen
import 'package:google_fonts/google_fonts.dart'; // For GoogleFonts

class ScanningWidget extends StatelessWidget {
  const ScanningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Museum Artifact Classifier', // Added title for clarity
      theme: ThemeData(
        primaryColor: AllColors.primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Using Inter font as per instructions
        appBarTheme: AppBarTheme(
          backgroundColor: AllColors.primaryColor,
          titleTextStyle: GoogleFonts.ebGaramond(
            color: AllColors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 21.0, // Fixed size to avoid sizer issues
          ),
          iconTheme: IconThemeData(color: AllColors.secondaryColor),
          // Removed centerTitle: true and shape for non-curved, non-centered title
        ),
      ),
      home: const ArtifactClassifierScreen(),
    );
  }
}

class ArtifactClassifierScreen extends StatefulWidget {
  const ArtifactClassifierScreen({super.key});

  @override
  State<ArtifactClassifierScreen> createState() => _ArtifactClassifierScreenState();
}

class _ArtifactClassifierScreenState extends State<ArtifactClassifierScreen> {
  Interpreter? _interpreter;
  List<String>? _labels;
  File? _image;
  String _predictionText = 'Scan an artifact to identify it';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _matchedArtifactData;
  String? _matchedHallNumber;
  Map<String, dynamic>? _museumData;
  List<Map<String, dynamic>>? _currentHallArtifacts; // Added to store all artifacts of the matched hall

  // Model constants
  static const int IMG_HEIGHT = 224;
  static const int IMG_WIDTH = 224;
  static const int NUM_CHANNELS = 3;

  // Special hall mappings for robust search
  final Map<String, String> _specialHalls = {
    'churches hall': '26',
    'corridor': 'corridor',
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadModel();
    await _loadMuseumData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/artifact_classifier.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).where((label) => label.isNotEmpty).toList();
      print('Model and labels loaded successfully!');
    } catch (e) {
      print('Failed to load model or labels: $e');
      setState(() => _predictionText = 'Error loading model. Please restart the app.');
    }
  }

  Future<void> _loadMuseumData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/MuseumCollection.json');
      _museumData = jsonDecode(jsonString);
      print('Museum data loaded successfully!');
    } catch (e) {
      print('Failed to load museum data: $e');
      // Potentially set an error message for the user if data is critical
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return; // Prevent picking if model is still loading

    setState(() {
      _isLoading = true;
      _predictionText = 'Scanning artifact...';
      _matchedArtifactData = null; // Clear previous match
      _matchedHallNumber = null;
      _currentHallArtifacts = null; // Clear previous hall artifacts
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
        await _processImage(_image!);
      } else {
        setState(() {
          _predictionText = 'No image selected.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _predictionText = 'Error picking image. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    if (_interpreter == null || _labels == null || _museumData == null) {
      setState(() {
        _predictionText = 'Model or museum data not ready yet. Please wait.';
        _isLoading = false;
      });
      return;
    }

    try {
      final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) throw Exception('Could not decode image');

      final img.Image resizedImage = img.copyResize(originalImage, width: IMG_WIDTH, height: IMG_HEIGHT);
      final inputBytes = Float32List(1 * IMG_HEIGHT * IMG_WIDTH * NUM_CHANNELS);
      final Uint8List pixelBytes = resizedImage.getBytes();

      int bytesPerPixel = pixelBytes.length ~/ (resizedImage.width * resizedImage.height);
      bytesPerPixel = bytesPerPixel < 3 ? 3 : bytesPerPixel; // Ensure at least 3 bytes per pixel

      int inputIndex = 0;
      for (int i = 0; i < pixelBytes.length; i += bytesPerPixel) {
        if (i + 2 < pixelBytes.length) { // Ensure enough bytes for R, G, B
          inputBytes[inputIndex++] = pixelBytes[i] / 255.0;
          inputBytes[inputIndex++] = pixelBytes[i + 1] / 255.0;
          inputBytes[inputIndex++] = pixelBytes[i + 2] / 255.0;
        } else {
          break; // Stop if incomplete pixel data
        }
      }

      final input = inputBytes.reshape([1, IMG_HEIGHT, IMG_WIDTH, NUM_CHANNELS]);
      final output = List<List<double>>.filled(1, List<double>.filled(_labels!.length, 0.0));
      _interpreter!.run(input, output);

      final List<double> probabilities = output[0];
      double maxProbability = 0.0;
      int predictedIndex = -1;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          predictedIndex = i;
        }
      }

      String predictedLabel = 'Unknown Artifact';
      if (predictedIndex != -1 && predictedIndex < _labels!.length) {
        predictedLabel = _labels![predictedIndex];
      }

      setState(() => _predictionText = predictedLabel); // Display the exact label from labels.txt
      await _searchArtifactInJson(predictedLabel);

    } catch (e) {
      print('Error during image processing: $e');
      setState(() => _predictionText = 'Error processing image. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Normalizes artifact names for comparison (lowercase, remove specific chars)
  String _normalizeName(String name) {
    return name.toLowerCase()
        .replaceAll("'s", "")
        .replaceAll("st.", "saint")
        .replaceAll(RegExp(r'[^a-z0-9 ]'), "") // Remove non-alphanumeric except space
        .trim();
  }

  // Normalizes hall names for comparison, using special mappings
  String _normalizeHallIdentifier(String hall) {
    hall = hall.toLowerCase().replaceAll("hall ", "").trim();
    return _specialHalls[hall] ?? hall; // Use special mapping if available, otherwise the trimmed hall
  }

  // Checks if predicted artifact name "matches like" actual artifact name
  bool _matchesArtifact(String predicted, String actual) {
    final normPred = _normalizeName(predicted);
    final normActual = _normalizeName(actual);

    // Exact match after normalization
    if (normPred == normActual) return true;
    // Contains match (either way)
    if (normActual.contains(normPred) || normPred.contains(normActual)) return true;

    // Word-by-word comparison (at least one common word)
    final predWords = normPred.split(' ').where((w) => w.isNotEmpty).toSet();
    final actualWords = normActual.split(' ').where((w) => w.isNotEmpty).toSet();

    return predWords.any((word) => actualWords.contains(word)) ||
        actualWords.any((word) => predWords.contains(word));
  }

  // Smart search for artifact in JSON based on predicted label
  Future<void> _searchArtifactInJson(String predictedLabel) async {
    final parts = predictedLabel.split(' found in hall ');
    if (parts.length != 2 || _museumData == null) {
      _matchedArtifactData = null; // No match if format is wrong or data missing
      _currentHallArtifacts = null; // Ensure this is also cleared
      return;
    }

    final artifactNameFromLabel = parts[0].trim();
    final hallIdentifierFromLabel = _normalizeHallIdentifier(parts[1]);

    // --- Phase 1: Exact match for artifact name AND hall ---
    for (final hall in _museumData!['halls']) {
      final jsonHallId = hall['hall_id']?.toString().toLowerCase() ?? '';
      final jsonHallName = hall['hall_name']?.toString().toLowerCase() ?? '';

      bool hallExactMatch = false;
      if (jsonHallId == hallIdentifierFromLabel) {
        hallExactMatch = true;
      } else if (jsonHallName == hallIdentifierFromLabel) {
        hallExactMatch = true;
      } else if (hallIdentifierFromLabel.startsWith('hall ') && jsonHallId == hallIdentifierFromLabel.substring(5)) {
        hallExactMatch = true;
      } else if (_specialHalls.containsValue(hallIdentifierFromLabel) &&
          (jsonHallId == hallIdentifierFromLabel || jsonHallName == hallIdentifierFromLabel)) {
        hallExactMatch = true;
      }

      if (hallExactMatch) {
        _currentHallArtifacts = List<Map<String, dynamic>>.from(hall['artifacts']);
        for (var i = 0; i < hall['artifacts'].length; i++) {
          final artifact = hall['artifacts'][i];
          final jsonArtifactName = artifact['Artifact Name']?.toString() ?? '';
          if (_normalizeName(artifactNameFromLabel) == _normalizeName(jsonArtifactName)) {
            setState(() {
              _matchedArtifactData = artifact;
              _matchedHallNumber = hall['hall_id'];
            });
            return; // Found exact match, exit
          }
        }
      }
    }

    // --- Phase 2: Fuzzy match for artifact name AND hall (if no exact match found) ---
    _matchedArtifactData = null; // Reset for fuzzy search
    _matchedHallNumber = null;
    _currentHallArtifacts = null; // Reset

    for (final hall in _museumData!['halls']) {
      final jsonHallId = hall['hall_id']?.toString().toLowerCase() ?? '';
      final jsonHallName = hall['hall_name']?.toString().toLowerCase() ?? '';

      bool hallFuzzyMatch = false;
      if (jsonHallId.contains(hallIdentifierFromLabel) || hallIdentifierFromLabel.contains(jsonHallId)) {
        hallFuzzyMatch = true;
      } else if (jsonHallName.contains(hallIdentifierFromLabel) || hallIdentifierFromLabel.contains(jsonHallName)) {
        hallFuzzyMatch = true;
      } else if (_specialHalls.containsValue(hallIdentifierFromLabel) &&
          (jsonHallId.contains(hallIdentifierFromLabel) || jsonHallName.contains(hallIdentifierFromLabel))) {
        hallFuzzyMatch = true;
      }


      if (hallFuzzyMatch) {
        _currentHallArtifacts = List<Map<String, dynamic>>.from(hall['artifacts']);
        for (var i = 0; i < hall['artifacts'].length; i++) {
          final artifact = hall['artifacts'][i];
          final jsonArtifactName = artifact['Artifact Name']?.toString() ?? '';
          if (_matchesArtifact(artifactNameFromLabel, jsonArtifactName)) { // Uses the "like" match
            setState(() {
              _matchedArtifactData = artifact;
              _matchedHallNumber = hall['hall_id'];
            });
            return; // Found fuzzy match, exit
          }
        }
      }
    }

    // If no match (exact or fuzzy) found, _matchedArtifactData remains null.
    _currentHallArtifacts = null; // Ensure this is cleared if no overall match
  }

  // Resets the state for a new scan
  void _newScan() {
    setState(() {
      _image = null;
      _predictionText = 'Scan an artifact to identify it';
      _matchedArtifactData = null;
      _matchedHallNumber = null;
      _currentHallArtifacts = null;
      _isLoading = false; // Ensure loading is off for new scan
    });
  }


  // Saves a scan entry to local history
  Future<void> _saveScanHistory({
    required String imagePath,
    required String predictedLabel,
    Map<String, dynamic>? matchedArtifactData,
    String? matchedHallNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = prefs.getStringList('scanHistory') ?? [];

    final scanEntry = {
      'imagePath': imagePath,
      'predictedLabel': predictedLabel,
      'timestamp': DateTime.now().toIso8601String(),
      'matchedArtifactData': matchedArtifactData,
      'matchedHallNumber': matchedHallNumber,
    };

    historyStrings.insert(0, jsonEncode(scanEntry)); // Add to the beginning
    if (historyStrings.length > 50) { // Limit history to the last 50 scans
      historyStrings = historyStrings.sublist(0, 50);
    }
    await prefs.setStringList('scanHistory', historyStrings);
    print('Scan history saved: $scanEntry');
  }

  // Navigates to the FullScreenImagePage
  void _navigateToArtifactDetails() async { // Made async to await _saveScanHistory
    if (_image == null) return; // Cannot navigate without an image

    if (_matchedArtifactData != null && _matchedHallNumber != null && _currentHallArtifacts != null) {
      // Find the index of the matched artifact within the current hall's artifacts
      int matchedIndex = _currentHallArtifacts!.indexOf(_matchedArtifactData!);
      if (matchedIndex == -1) {
        matchedIndex = 0; // Fallback
      }

      // Save to history before navigating
      await _saveScanHistory(
        imagePath: _matchedArtifactData!['Image'], // Use JSON image path for history
        predictedLabel: _predictionText,
        matchedArtifactData: _matchedArtifactData,
        matchedHallNumber: _matchedHallNumber,
      );

      // Navigate with JSON data if a match was found
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImagePage(
            imagePath: _matchedArtifactData!['Image'], // Image path from JSON
            hallNumber: _matchedHallNumber!, // Hall number from JSON
            imageIndex: matchedIndex, // Pass the found index
            artifacts: _currentHallArtifacts!, // Pass the entire list of artifacts for the hall
            isDataAvailable: true, // Indicate that JSON data is available
            scannedArtifactName: _predictionText, // Pass the scanned name
          ),
        ),
      );
    } else {
      // Save to history before navigating (for non-matched scans)
      await _saveScanHistory(
        imagePath: _image!.path, // Use scanned image path for history
        predictedLabel: _predictionText,
        matchedArtifactData: null, // No matched data
        matchedHallNumber: null, // No matched hall
      );

      // Navigate with scanned image if no JSON match
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImagePage(
            imagePath: _image!.path, // Pass the path of the scanned image
            hallNumber: 'N/A', // Placeholder
            imageIndex: 0, // Placeholder index, as artifacts list will be empty
            artifacts: const [], // Empty list as no JSON data found
            isDataAvailable: false, // Indicate that JSON data is NOT available
            scannedArtifactName: _predictionText, // Pass the scanned name
          ),
        ),
      );
    }
  }

  // Navigates to the ScanHistoryScreen
  void _navigateToScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanHistoryScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Scanner'), // Title from theme
        // centerTitle is false by default, and shape is removed in theme for non-curved
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: AllColors.secondaryColor),
            onPressed: _navigateToScanHistory,
            tooltip: 'View Scan History',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AllColors.secondaryColor),
            onPressed: _newScan,
            tooltip: 'New Scan',
          ),
        ],
      ),
      backgroundColor: AllColors.background, // Apply background color from theme
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"), // Apply background image from theme
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Display picked image or a themed placeholder
                _image == null
                    ? Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AllColors.third, // Use theme color for placeholder background
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AllColors.primaryColor, width: 2), // Use theme color for border
                  ),
                  child: Icon(
                    Icons.camera_alt, // More thematic icon for image placeholder
                    size: 100,
                    color: AllColors.secondaryColor.withOpacity(0.6), // Themed icon color
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _image!,
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 30),
                // Display prediction text or loading indicator
                _isLoading && _image != null
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AllColors.primaryColor), // Themed loading indicator color
                )
                    : Text(
                  _predictionText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ebGaramond(
                    color: AllColors.primaryColor, // Themed text color
                    fontWeight: FontWeight.w600,
                    fontSize: 22.0, // Fixed size
                  ),
                ),
                const SizedBox(height: 20),
                // "View Artifact Details" Button (always displayed after scan if _image is not null)
                if (_image != null && !_isLoading)
                  ElevatedButton(
                    onPressed: _navigateToArtifactDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AllColors.primaryColor, // Themed button background
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners for button
                      ),
                      elevation: 5, // Shadow effect for button
                    ),
                    child: Text(
                      'View Artifact Details',
                      style: GoogleFonts.poppins(
                        color: AllColors.secondaryColor, // Themed font and color for button text
                        fontWeight: FontWeight.w600,
                        fontSize: 15.0, // Fixed size
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                // Buttons for picking images (Gallery and Camera)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: _buildThemedElevatedButton(
                        icon: Icons.photo_library,
                        label: 'Pick from Gallery',
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 10), // Add some spacing between buttons
                    Expanded(
                      child: _buildThemedElevatedButton(
                        icon: Icons.camera_alt,
                        label: 'Take Photo',
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to create consistently themed ElevatedButtons
  Widget _buildThemedElevatedButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: AllColors.secondaryColor), // Themed icon color
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: AllColors.secondaryColor, // Themed label text style
          fontWeight: FontWeight.w600,
          fontSize: 15.0, // Fixed size
        ),
      ),
      onPressed: _isLoading ? null : onPressed, // Disable button if loading
      style: ElevatedButton.styleFrom(
        backgroundColor: AllColors.primaryColor, // Themed button background color
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners for buttons
        ),
        elevation: 5, // Shadow effect
      ),
    );
  }
}
