import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import 'AllColors.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts

import 'FullScreenImage.dart';

class HallCollectionScreen extends StatefulWidget {
  final String hallNumber;
  const HallCollectionScreen({super.key, required this.hallNumber});

  @override
  State<HallCollectionScreen> createState() => _HallCollectionScreenState();
}

class _HallCollectionScreenState extends State<HallCollectionScreen> {
  late List<Map<String, dynamic>> _artifacts = [];
  final _cacheManager = CacheManager(
    Config(
      'museum_images',
      maxNrOfCacheObjects: 200,
      stalePeriod: const Duration(days: 30),
    ),
  );
  String _hallName = "";

  // Added for search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredArtifacts = [];

  // Added for filter options
  String _selectedMaterialFilter = 'All';
  String _selectedDatingFilter = 'All';
  final bool _isFilterOpen =
  false; // Added to manage filter box visibility,  but it is not used

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
  }

  @override
  void dispose() {
    _cacheManager.emptyCache();
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _loadArtifacts() {
    DefaultAssetBundle.of(context)
        .loadString("assets/MuseumCollection.json")
        .then((jsonString) {
      final jsonData = jsonDecode(jsonString);
      for (var hall in jsonData['halls']) {
        if (hall['hall_id'] == widget.hallNumber) {
          _hallName = hall['hall_name'];
          _artifacts = List<Map<String, dynamic>>.from(hall['artifacts']);
          break;
        }
      }
      _filteredArtifacts =
          _artifacts; // Initialize filtered list with all artifacts
      _applyFilters(); // Apply filters on initial load
      if (mounted) {
        setState(() {});
      }
    })
        .catchError((error) {
      print("Error loading JSON: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $error')),
        );
      }
    });
  }

  // Function to filter artifacts based on search query
  void _filterArtifacts(String query) {
    if (query.isEmpty) {
      _filteredArtifacts = _artifacts;
    } else {
      String lowercaseQuery = query.toLowerCase();
      _filteredArtifacts = _artifacts.where((artifact) {
        // Ensure null checks for artifact fields
        return (artifact['Artifact Name']?.toLowerCase().contains(
          lowercaseQuery,
        ) ??
            false) ||
            (artifact['Description']?.toLowerCase().contains(
              lowercaseQuery,
            ) ??
                false) ||
            (artifact['Material']?.toLowerCase().contains(lowercaseQuery) ??
                false) ||
            (artifact['Provenance']?.toLowerCase().contains(
              lowercaseQuery,
            ) ??
                false) ||
            (artifact['Dating']?.toLowerCase().contains(lowercaseQuery) ??
                false);
      }).toList();
    }
    _applyFilters(); // Apply filters after search
  }

  // Function to apply selected filters
  void _applyFilters() {
    List<Map<String, dynamic>> tempFilteredList = List.from(_filteredArtifacts);

    // Apply material filter if not 'All'
    if (_selectedMaterialFilter != 'All') {
      tempFilteredList = tempFilteredList.where((artifact) {
        return artifact['Material'] == _selectedMaterialFilter;
      }).toList();
    }

    // Apply dating filter if not 'All'
    if (_selectedDatingFilter != 'All') {
      tempFilteredList = tempFilteredList.where((artifact) {
        return artifact['Dating'] == _selectedDatingFilter;
      }).toList();
    }

    setState(() {
      _filteredArtifacts = tempFilteredList;
    });
  }

  // Function to get unique material options for filter dropdown
  List<String> get _materialOptions {
    Set<String> materials = {'All'};
    for (var artifact in _artifacts) {
      // Ensure 'Material' is treated as a String and handle potential nulls
      if (artifact['Material'] is String && (artifact['Material'] as String).isNotEmpty) {
        materials.add(artifact['Material'] as String);
      }
    }
    return materials.toList();
  }

  // Function to get unique dating options for filter dropdown
  List<String> get _datingOptions {
    Set<String> datings = {'All'};
    for (var artifact in _artifacts) {
      // Ensure 'Dating' is treated as a String and handle potential nulls
      if (artifact['Dating'] is String && (artifact['Dating'] as String).isNotEmpty) {
        datings.add(artifact['Dating'] as String);
      } else {
        datings.add('Unknown'); // Add 'Unknown' for null or empty dating values
      }
    }
    return datings.toList();
  }


  // Function to reset filters
  void _resetFilters() {
    setState(() {
      _selectedMaterialFilter = 'All';
      _selectedDatingFilter = 'All';
      _filteredArtifacts =
          _artifacts; // Reset to the original list of artifacts
      _applyFilters();
    });
  }

  // Function to clear search
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filterArtifacts(''); // Pass empty string to show all artifacts
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hallName,
          style: GoogleFonts.ebGaramond( // Replaced Allfonts.header
            color: AllColors.secondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 21.0,
          ),
        ),
        backgroundColor: AllColors.primaryColor,
        iconTheme: IconThemeData(color: AllColors.secondaryColor),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    // Added background color
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterArtifacts,
                          decoration: InputDecoration(
                            labelText: 'Search Artifacts',
                            labelStyle: TextStyle(
                              color: AllColors.primaryColor,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AllColors.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AllColors.primaryColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AllColors.primaryColor,
                              ),
                            ),
                          ),
                          style: TextStyle(color: Colors.black), // Text color
                        ),
                      ),
                      IconButton(
                        // Clear search button
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    ],
                  ),
                ),
              ),
              // Filter and Clear Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showFilterDialog(
                          context,
                        ); // Show filter dialog, _showFilterDialog defined below
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AllColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Filter'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredArtifacts.isNotEmpty
                    ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 32,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredArtifacts.length,
                  itemBuilder: (context, index) {
                    return _buildImageItem(context, index);
                  },
                )
                    : Center( // Changed to Center for better visibility of "No artifacts found."
                  child: Text(
                    'No artifacts found.',
                    style: GoogleFonts.poppins( // Replaced TextStyle
                      fontSize: 18,
                      color: AllColors.bodytext,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    final artifact = _filteredArtifacts[index];
    // Safely get imagePath, providing a fallback if null or not a String
    final String imagePath = (artifact['Image'] as String?) ?? 'assets/images/placeholder.png'; // Fallback image

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the maximum size available for the image
        final maxSize = constraints.maxWidth;

        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: imagePath, // Use the potentially fallback imagePath
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _showFullScreenImage(context, imagePath, index),
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: maxSize,
                        height: maxSize,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          width: maxSize,
                          height: maxSize,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: GoogleFonts.poppins( // Replaced Allfonts.body
                                  color: AllColors.bodytext,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  artifact['Artifact Name']?.toString() ?? 'Unknown Artifact', // Handle null artifact name
                  style: GoogleFonts.poppins( // Replaced TextStyle
                    color: AllColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImagePage(
            imagePath: imagePath,
            hallNumber: widget.hallNumber,
            imageIndex: index,
            artifacts: _artifacts,
            isDataAvailable: true,
            scannedArtifactName: _artifacts[index]['Artifact Name']?.toString() ?? 'N/A', // Pass the artifact name
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // Function to show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Artifacts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMaterialFilter,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMaterialFilter = newValue;
                        });
                      }
                    },
                    items: _materialOptions
                        .map<DropdownMenuItem<String>>((
                        String value,
                        ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedDatingFilter,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDatingFilter = newValue;
                        });
                      }
                    },
                    items: _datingOptions
                        .map<DropdownMenuItem<String>>((
                        String value,
                        ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Dating',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AllColors.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Apply',
                    style: TextStyle(color: AllColors.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _resetFilters();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(color: AllColors.primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
