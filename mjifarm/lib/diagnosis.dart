import 'package:flutter/material.dart';
import "plant_identification.dart"; // Assuming this contains callPlantDiagnosisVercel and getCurrentUserLocation
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // Required for file system access
import 'dart:io'; // Required for File
import 'package:permission_handler/permission_handler.dart'; // Required for requesting storage permissions
import 'package:open_filex/open_filex.dart'; // Required for opening the file
import 'package:http/http.dart' as http; // For sending HTTP requests
import 'package:firebase_database/firebase_database.dart'; // NEW: Import Firebase Realtime Database

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
  double _confidenceLevel = 0.0;
  List<String> _recommendations = [];
  List<String> _rawApiResponse = []; // This seems unused, consider removing if not needed
  List<String> _relatedDiseaseImages = [];

  Uint8List? _capturedImageBytes;
  String? _capturedImageBase64; // Store base64 for sending to expert review

  String? _currentDiagnosisId; // To store the ID of the current diagnosis record
  String? _currentCropLogId; // NEW: To store the cropLogId for the current diagnosis

  // Function to show image source selection sheet
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
                  _handleDiagnosisButtonPress(
                    ImageSource.camera,
                  ); // Call with camera source
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _handleDiagnosisButtonPress(
                    ImageSource.gallery,
                  ); // Call with gallery source
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
  Future<void> _handleDiagnosisButtonPress(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _currentLocationText = "Getting location...";
      _diagnosisResult = "Diagnosing...";
      _confidenceLevel = 0.0; // Reset confidence
      _recommendations = [];
      _relatedDiseaseImages = [];
      _capturedImageBytes = null; // Clear previous image
      _capturedImageBase64 = null; // Clear previous base64
      _currentDiagnosisId = null; // Clear previous diagnosis ID
      _currentCropLogId = null; // NEW: Clear previous cropLogId
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
        _capturedImageBase64 = base64Image; // Store base64 for potential expert review
      });

      Position? currentPosition = await getCurrentUserLocation();

      if (currentPosition != null) {
        setState(() {
          _latitude = currentPosition.latitude;
          _longitude = currentPosition.longitude;
          _currentLocationText =
              "Lat: ${_latitude?.toStringAsFixed(4)}, Lon: ${_longitude?.toStringAsFixed(4)}";
        });
      } else {
        setState(() {
          _currentLocationText = "Failed to get location.";
        });
      }

      String dummyCropLogId = "test_crop_log_123"; // This is the ID passed to Vercel
      String dummyPlantId = "test_plant_456";

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
          _diagnosisResult =
              diagnosisDetails['pestOrDisease'] ?? "Unknown Issue";
          // Ensure confidenceLevel is a double
          _confidenceLevel =
              (diagnosisDetails['confidenceLevel'] as num?)?.toDouble() ?? 0.0;
          if (diagnosisDetails['recommendations'] is List) {
            _recommendations = List<String>.from(
              diagnosisDetails['recommendations'],
            );
          } else {
            _recommendations = [];
          }

          if (diagnosisDetails['relatedDiseaseImages'] is List) {
            _relatedDiseaseImages = List<String>.from(
              diagnosisDetails['relatedDiseaseImages'],
            );
          } else {
            _relatedDiseaseImages = [];
          }
          // NEW: Capture the diagnosis ID and cropLogId returned from the Vercel function
          _currentDiagnosisId = diagnosisDetails['diagnosisId'] as String?;
          _currentCropLogId = diagnosisDetails['cropLogId'] as String?; // <-- NEW
        });
      } else {
        setState(() {
          _diagnosisResult = "Diagnosis failed.";
          _confidenceLevel = 0.0;
          _currentDiagnosisId = null; // Clear ID on failure
          _currentCropLogId = null; // NEW: Clear cropLogId on failure
        });
      }
    } else {
      print("Image capture/selection failed or cancelled.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image capture/selection failed or cancelled.'),
        ),
      );
      setState(() {
        _currentLocationText = "Image selection cancelled.";
        _diagnosisResult = "Image selection cancelled.";
        _confidenceLevel = 0.0;
        _currentDiagnosisId = null; // Clear ID on cancellation
        _currentCropLogId = null; // NEW: Clear cropLogId on cancellation
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Report Generation Function (unchanged) ---
  Future<void> _generateDiagnosisReport() async {
    // Only generate report if a valid diagnosis is present
    if (_diagnosisResult == "No diagnosis yet." ||
        _diagnosisResult == "Diagnosing..." ||
        _diagnosisResult == "Diagnosis failed." ||
        _diagnosisResult == "Image selection cancelled." ||
        _capturedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid diagnosis to generate a report.'),
        ),
      );
      return;
    }

    // 1. Request Storage Permission (for Android specifically)
    // On iOS, storage permissions are often covered by photo library permissions
    // On web, file downloads directly, no explicit permission needed.
    // This is good practice for cross-platform.
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied. Cannot save report.'),
            ),
          );
          return;
        }
      }
    }

    try {
      // 2. Format the report content
      String reportContent = "--- Plant Diagnosis Report ---\n\n";
      reportContent +=
          "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}\n"; // Just date
      reportContent +=
          "Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}\n\n"; // Just time

      if (_capturedImageBytes != null) {
        // In a real report, you might upload this image to storage (e.g., Firebase Storage)
        // and include its URL here, instead of a base64 string.
        // For a simple text file, we note that an image was captured.
        reportContent +=
            "Image Captured: Yes (Image data not embedded in text report for brevity)\n\n";
      }

      reportContent += "Location: $_currentLocationText\n\n";
      reportContent += "Diagnosis Result: $_diagnosisResult\n";
      if (_confidenceLevel > 0) {
        reportContent +=
            "Confidence Level: ${_confidenceLevel.toStringAsFixed(1)}%\n\n";
      } else {
        reportContent += "\n";
      }

      reportContent += "Recommendations:\n";
      if (_recommendations.isNotEmpty) {
        for (int i = 0; i < _recommendations.length; i++) {
          reportContent += "${i + 1}. ${_recommendations[i]}\n";
        }
      } else {
        reportContent += "No specific recommendations provided.\n";
      }
      reportContent += "\n";

      reportContent += "Related Disease Images (URLs):\n";
      if (_relatedDiseaseImages.isNotEmpty) {
        for (int i = 0; i < _relatedDiseaseImages.length; i++) {
          reportContent += "${i + 1}. ${_relatedDiseaseImages[i]}\n";
        }
      } else {
        reportContent += "No related images found.\n";
      }
      reportContent += "\n--- End of Report ---";

      // 3. Get local directory for saving the file
      final directory = await getExternalStorageDirectory();
      final fileName =
          'diagnosis_report_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory?.path}/$fileName');

      // 4. Write content to the file
      await file.writeAsString(reportContent);

      // 5. Open the file
      final result = await OpenFilex.open(file.path);

      // 6. Show success/failure message
      if (result.type == OpenResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated and saved to: ${file.path}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open report: ${result.message}')),
        );
      }
    } catch (e) {
      print('Error generating report: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }
  // --- End of Report Generation Function ---

  // --- NEW: Request Expert Review Function ---
  Future<void> _requestExpertReview() async {
    // Only allow review request if a valid diagnosis has been made AND we have its IDs
    if (_diagnosisResult == "No diagnosis yet." ||
        _diagnosisResult == "Diagnosing..." ||
        _diagnosisResult == "Diagnosis failed." ||
        _diagnosisResult == "Image selection cancelled." ||
        _currentDiagnosisId == null || // Check for diagnosis ID
        _currentCropLogId == null) { // NEW: Check for cropLogId
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perform a diagnosis first to request expert review.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Indicate that a request is in progress
    });

    try {
      // Get a reference to the specific diagnosis record in Firebase Realtime Database
      // Use the full path: crop_logs/{cropLogId}/diagnoses/{diagnosisId}
      final DatabaseReference diagnosisRef = FirebaseDatabase.instance
          .ref('crop_logs')
          .child(_currentCropLogId!) // Use the current crop log ID
          .child('diagnoses')
          .child(_currentDiagnosisId!); // Use the current diagnosis ID

      // Update the 'reviewStatus' attribute to 'pending_expert_review'
      await diagnosisRef.update({
        'reviewStatus': 'pending_expert_review',
        'reviewRequestedAt': ServerValue.timestamp, // Add a timestamp for when review was requested
        // You might also add the userId who requested the review if authenticated
        // 'requestedByUserId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expert review requested successfully! Status updated in database.'),
          backgroundColor: Colors.green,
        ),
      );
      print('Diagnosis ID ${_currentDiagnosisId} status updated to pending_expert_review in cropLog ${_currentCropLogId}.');

    } catch (e) {
      print('Error requesting expert review (Firebase update failed): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting expert review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // End loading state
      });
    }
  }
  // --- End of NEW: Request Expert Review Function ---

  @override
  Widget build(BuildContext context) {
    // Determine if a valid diagnosis is present to enable review/report buttons
    bool hasValidDiagnosis = !(_diagnosisResult == "No diagnosis yet." ||
        _diagnosisResult == "Diagnosing..." ||
        _diagnosisResult == "Diagnosis failed." ||
        _diagnosisResult == "Image selection cancelled." ||
        _currentDiagnosisId == null ||
        _currentCropLogId == null); // NEW: Check if cropLogId is available

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Diagnosis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _showImageSourceSelectionSheet,
              icon:
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
              label:
                  _isLoading
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
                  const Text(
                    'Your Plant Image:',
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _diagnosisResult,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  if (_confidenceLevel > 0 &&
                      _diagnosisResult != "No diagnosis yet." &&
                      _diagnosisResult != "Diagnosing..." &&
                      _diagnosisResult != "Image selection cancelled.")
                    Text(
                      'Confidence: ${_confidenceLevel.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ..._recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '• $rec',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_recommendations.isEmpty &&
                _diagnosisResult != "No diagnosis yet." &&
                _diagnosisResult != "Diagnosing...")
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // --- Generate Report Button ---
            ElevatedButton.icon(
              onPressed: _isLoading || !hasValidDiagnosis ? null : _generateDiagnosisReport,
              icon: const Icon(Icons.description),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Changed color for distinction
                foregroundColor: Colors.white,
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
            const SizedBox(height: 10), // Space between buttons

            // --- NEW: Request Expert Review Button ---
            ElevatedButton.icon(
              onPressed: _isLoading || !hasValidDiagnosis ? null : _requestExpertReview,
              icon: const Icon(Icons.person_search), // Icon for expert review
              label: const Text('Request Expert Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Distinct color
                foregroundColor: Colors.white,
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
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }
}