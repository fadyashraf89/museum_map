import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io'; // For File.fromUri
import 'package:google_fonts/google_fonts.dart';

import 'AllColors.dart';
import 'FullScreenImage.dart'; // To navigate back to artifact details

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> _scanHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> historyStrings = prefs.getStringList('scanHistory') ?? [];
      setState(() {
        _scanHistory = historyStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading scan history: $e');
      setState(() {
        _isLoadingHistory = false;
        // Optionally show an error message to the user
      });
    }
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scanHistory');
    setState(() {
      _scanHistory = [];
    });
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scan history cleared!',
          style: GoogleFonts.poppins().copyWith(color: AllColors.secondaryColor),
        ),
        backgroundColor: AllColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.ebGaramond(
            color: AllColors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 21.0,
          ),
        ),
        backgroundColor: AllColors.primaryColor,
        iconTheme: IconThemeData(color: AllColors.secondaryColor), // Back button color
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever, color: AllColors.secondaryColor),
            onPressed: _scanHistory.isEmpty ? null : _clearAllHistory, // Disable if history is empty
            tooltip: 'Clear All History',
          ),
        ],
      ),
      backgroundColor: AllColors.background,
      body: Container( // Added Container for background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"), // Apply background image
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoadingHistory
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AllColors.primaryColor),
          ),
        )
            : _scanHistory.isEmpty
            ? Center(
          child: Text(
            'No scan history yet!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AllColors.bodytext,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _scanHistory.length,
          itemBuilder: (context, index) {
            final scanEntry = _scanHistory[index];
            final imagePath = scanEntry['imagePath'] as String?;
            final predictedLabel = scanEntry['predictedLabel'] as String? ?? 'N/A';
            final timestamp = scanEntry['timestamp'] as String? ?? '';
            final matchedArtifactData = scanEntry['matchedArtifactData'] as Map<String, dynamic>?;
            final matchedHallNumber = scanEntry['matchedHallNumber'] as String?;

            // Determine if data was available (i.e., if it was a JSON match)
            final isDataAvailable = matchedArtifactData != null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: AllColors.third, // Card background color
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () {
                  // Reconstruct parameters for FullScreenImagePage based on history entry
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImagePage(
                        imagePath: imagePath ?? 'assets/images/placeholder.png', // Fallback image
                        hallNumber: matchedHallNumber ?? 'N/A',
                        imageIndex: 0, // Not directly stored, use 0 for history view
                        artifacts: isDataAvailable ? [matchedArtifactData!] : const [], // Pass matched data as a list for FullScreenImagePage
                        isDataAvailable: isDataAvailable,
                        scannedArtifactName: predictedLabel,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Display image thumbnail
                      if (imagePath != null && imagePath.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imagePath.startsWith('assets/')
                              ? Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                              : Image.file(
                            File(imagePath),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDataAvailable
                                  ? (matchedArtifactData!['Artifact Name'] ?? predictedLabel)
                                  : predictedLabel,
                              style: GoogleFonts.merriweather(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AllColors.primaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hall: ${matchedHallNumber ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AllColors.bodytext,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AllColors.bodytext.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.toLocal().day}/${dateTime.toLocal().month}/${dateTime.toLocal().year} ${dateTime.toLocal().hour}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }
}
