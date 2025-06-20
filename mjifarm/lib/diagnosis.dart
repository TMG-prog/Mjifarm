import 'package:flutter/material.dart';
import "plant_identification.dart"; 
import 'package:geolocator/geolocator.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List
import 'dart:convert';

// Import geolocator for location
// Import your Plant Identification page
// ... other imports for Firebase, http, image_picker etc.
// Ensure you have the callPlantDiagnosisVercel function defined as previously discussed.
class MyDiagnosisScreen extends StatefulWidget {
  const MyDiagnosisScreen({super.key});

  @override
  State<MyDiagnosisScreen> createState() => _MyDiagnosisScreenState();
}

class _MyDiagnosisScreenState extends State<MyDiagnosisScreen> {
  bool _isLoading = false;
  String _currentLocationText = "Location not determined.";
  double? _latitude;
  double? _longitude;
  String _diagnosisResult = "No diagnosis yet.";
  double _confidenceLevel = 0.0; // NEW: To store confidence level
  List<String> _recommendations = [];
  List<String> _relatedDiseaseImages = [];
  Uint8List? _capturedImageBytes;

  // NEW: Function to show image source selection sheet
  void _showImageSourceSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _handleDiagnosisButtonPress(ImageSource.camera); // Call with camera source
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _handleDiagnosisButtonPress(ImageSource.gallery); // Call with gallery source
                },
              ),
            ],
          ),
        );
      },
    );
  }
Future<String?> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(
    source: source,
    maxWidth: 800, // Optional: compress image for smaller payload
    maxHeight: 600, // Optional: compress image for smaller payload
    imageQuality: 70, // Optional: compress image quality
  );

  if (pickedFile != null) {
    try {
      // Read the file as bytes
      Uint8List imageBytes = await pickedFile.readAsBytes();
      // Convert bytes to Base64 string
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error reading image bytes or encoding to Base64: $e");
      return null;
    }
  }
  return null; // User cancelled image selection
}
  // Modified: _handleDiagnosisButtonPress now accepts an ImageSource
    // Modified: _handleDiagnosisButtonPress now accepts an ImageSource
  Future<void> _handleDiagnosisButtonPress(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _currentLocationText = "Getting location...";
      _diagnosisResult = "Diagnosing...";
      _confidenceLevel = 0.0; // Reset confidence
      _recommendations = [];
      _relatedDiseaseImages = [];
      _capturedImageBytes = null; // Clear previous image
    });

    // Call the refactored image picker
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      setState(() {
        _capturedImageBytes = imageBytes; // Store for display
      });

      Position? currentPosition = await getCurrentUserLocation();

      if (currentPosition != null) {
        setState(() {
          _latitude = currentPosition.latitude;
          _longitude = currentPosition.longitude;
          _currentLocationText = "Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}";
        });
      } else {
        setState(() {
          _currentLocationText = "Failed to get location.";
        });
      }

      String dummyCropLogId = "test_crop_log_123"; // Replace with actual cropLogId
      String dummyPlantId = "test_plant_456";     // Replace with actual plantId

      Map<String, dynamic>? diagnosisDetails = await callPlantDiagnosisVercel(
        base64Image,
        dummyCropLogId,
        dummyPlantId,
        context,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (diagnosisDetails != null) {
        setState(() {
          _diagnosisResult = diagnosisDetails['pestOrDisease'] ?? "Unknown Issue";
          // Ensure confidenceLevel is a double
          _confidenceLevel = (diagnosisDetails['confidenceLevel'] as num?)?.toDouble() ?? 0.0;
          if (diagnosisDetails['recommendations'] is List) {
            _recommendations = List<String>.from(diagnosisDetails['recommendations']);
          } else {
            _recommendations = [];
          }
          if (diagnosisDetails['relatedDiseaseImages'] is List) {
            _relatedDiseaseImages = List<String>.from(diagnosisDetails['relatedDiseaseImages']);
          } else {
            _relatedDiseaseImages = [];
          }
        });
      } else {
        setState(() {
          _diagnosisResult = "Diagnosis failed.";
          _confidenceLevel = 0.0;
        });
      }

    } else {
      print("Image capture/selection failed or cancelled.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image capture/selection failed or cancelled.')),
      );
      setState(() {
        _currentLocationText = "Image selection cancelled.";
        _diagnosisResult = "Image selection cancelled.";
        _confidenceLevel = 0.0;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Diagnosis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _showImageSourceSelectionSheet,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: _isLoading
                  ? const Text('Diagnosing...')
                  : const Text('Diagnose Plant Issue'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display captured image
            if (_capturedImageBytes != null)
              Column(
                children: [
                  const Text('Your Plant Image:', style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      _capturedImageBytes!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            
            // Location
            Text(
              _currentLocationText,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Diagnosis Result Section
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.lightGreen.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.lightGreen.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'AI Diagnosis:',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _diagnosisResult,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  if (_confidenceLevel > 0 && _diagnosisResult != "No diagnosis yet." && _diagnosisResult != "Diagnosing..." && _diagnosisResult != "Image selection cancelled.")
                    Text(
                      'Confidence: ${_confidenceLevel.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 16, color: Colors.green, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recommendations Section
            if (_recommendations.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Recommendations:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ..._recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• $rec',
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                            textAlign: TextAlign.start,
                          ),
                        )).toList(),
                  ],
                ),
              ),
            if (_recommendations.isEmpty && _diagnosisResult != "No diagnosis yet." && _diagnosisResult != "Diagnosing...")
              const Text(
                'No specific recommendations available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),

            // Related Images Section
            if (_relatedDiseaseImages.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Related Images:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _relatedDiseaseImages.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _relatedDiseaseImages[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
