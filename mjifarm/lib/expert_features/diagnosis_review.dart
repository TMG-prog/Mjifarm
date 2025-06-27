import 'dart:io';
import 'dart:convert'; // For base64Decode

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:open_filex/open_filex.dart'; // Make sure this is imported
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DiagnosisReviewContent extends StatefulWidget {
  const DiagnosisReviewContent({super.key});

  @override
  State<DiagnosisReviewContent> createState() => _DiagnosisReviewContentState();
}

class _DiagnosisReviewContentState extends State<DiagnosisReviewContent> {
  late DatabaseReference _cropLogsRef;
  List<Map<String, dynamic>> _diagnoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cropLogsRef = FirebaseDatabase.instance.ref('crop_logs');
    _listenToDiagnoses();
  }

  void _listenToDiagnoses() {
    _cropLogsRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        final List<Map<String, dynamic>> fetchedDiagnoses = [];
        if (data != null && data is Map) {
          data.forEach((cropLogId, cropLogValue) {
            if (cropLogValue is Map &&
                cropLogValue['diagnoses'] != null &&
                cropLogValue['diagnoses'] is Map) {
              Map<dynamic, dynamic> diagnosesMap = Map<dynamic, dynamic>.from(
                cropLogValue['diagnoses'],
              );
              diagnosesMap.forEach((diagId, diagValue) {
                if (diagValue is Map) {
                  fetchedDiagnoses.add({
                    'id': diagId,
                    'cropLogId': cropLogId,
                    ...Map<String, dynamic>.from(diagValue),
                  });
                }
              });
            }
          });
        }
        setState(() {
          _diagnoses = fetchedDiagnoses;
          _isLoading = false;
        });
      },
      onError: (error) {
        print("Error listening to diagnoses: $error");
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Error fetching diagnoses: $error", Colors.red);
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  // Helper function to get the appropriate ImageProvider (Network or Memory)
  ImageProvider? _getDiagnosisImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    // Heuristic: If it starts with 'http' or 'https', it's likely a network URL.
    // Otherwise, assume it's a Base64 string.
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    } else {
      try {
        // If it's a Base64 string, it might have the data URI prefix (e.g., "data:image/jpeg;base64,...")
        // Split by comma to get just the Base64 data part.
        final String base64String =
            imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print("Error decoding Base64 image for diagnosis: $e");
        return null; // Return null if decoding fails
      }
    }
  }

  Future<void> _handleReview(String diagnosisId) async {
    // ... (previous code to find specificDiagnosis remains the same)
    Map<String, dynamic>? specificDiagnosis;
    for (var diag in _diagnoses) {
      if (diag['id'] == diagnosisId) {
        specificDiagnosis = diag;
        break;
      }
    }

    if (specificDiagnosis == null) {
      _showSnackBar('Diagnosis with ID "$diagnosisId" not found.', Colors.red);
      return;
    }

    // Now, specificDiagnosis is guaranteed to be non-null.
    String pestOrDisease = specificDiagnosis['pestOrDisease'] ?? 'N/A';
    double confidenceLevel =
        (specificDiagnosis['confidenceLevel'] as num?)?.toDouble() ?? 0.0;
    String diagnosisDate =
        specificDiagnosis['date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
              specificDiagnosis['date'],
            ).toLocal().toString().split(' ')[0]
            : 'N/A';
    List<dynamic> recommendationsRaw =
        specificDiagnosis['recommendations'] ?? [];

    // FIX START: Handle rawApiResponse which might be a Map or a List
    List<String> rawApiResponse = [];
    final dynamic rawApiData =
        specificDiagnosis['rawApiResponse']; // Get the raw data
    dynamic relatedDiseaseImages = specificDiagnosis['relatedDiseaseImages'];

    if (rawApiData != null) {
      if (rawApiData is Map) {
        // If it's a Map, convert its values to a List of Strings
        rawApiResponse = List<String>.from(
          rawApiData.values.map((e) => e.toString()),
        );
      } else if (rawApiData is Iterable) {
        // This handles Lists, as List is an Iterable
        rawApiResponse = List<String>.from(rawApiData.map((e) => e.toString()));
      }
      // If rawApiData is neither a Map nor an Iterable, rawApiResponse will remain an empty list,
      // which is a safe default.
    }
    // FIX END

    String diagnosisResult =
        specificDiagnosis['pestOrDisease']?.toString() ?? 'N/A';

    List<String> recommendations = List<String>.from(
      recommendationsRaw.map((rec) => rec.toString()),
    );

    // ... (rest of your _handleReview function remains the same)
    // --- Permission Request ---
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
      String reportContent = "--- Plant Diagnosis Report ---\n\n";
      reportContent += "Diagnosis ID: $diagnosisId\n";
      reportContent += "Diagnosis Date: $diagnosisDate\n";
      reportContent +=
          "Report Generated Date: ${DateTime.now().toLocal().toString().split(' ')[0]}\n";
      reportContent +=
          "Report Generated Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}\n\n";

      reportContent += "Diagnosis Result: $diagnosisResult\n";
      if (confidenceLevel > 0) {
        reportContent +=
            "Confidence Level: ${confidenceLevel.toStringAsFixed(1)}%\n\n";
      } else {
        reportContent += "\n";
      }

      reportContent += "Recommendations:\n";
      if (recommendations.isNotEmpty) {
        for (int i = 0; i < recommendations.length; i++) {
          reportContent += "${i + 1}. ${recommendations[i]}\n";
        }
      } else {
        reportContent += "No specific recommendations provided.\n";
      }
      reportContent += "\n";

      reportContent += "Related Disease Images (URLs):\n";
      if (relatedDiseaseImages.isNotEmpty) {
        // Assuming 'relatedDiseaseImages' is still directly a List of Strings or handled elsewhere
        for (int i = 0; i < relatedDiseaseImages.length; i++) {
          reportContent += "${i + 1}. ${relatedDiseaseImages[i]}\n";
        }
      } else {
        reportContent += "No related images found.\n";
      }
      reportContent += "\n";

      // Include rawApiResponse in the report if you want to see its content
      reportContent += "Raw API Response:\n";
      if (rawApiResponse.isNotEmpty) {
        for (int i = 0; i < rawApiResponse.length; i++) {
          reportContent += "${i + 1}. ${rawApiResponse[i]}\n";
        }
      } else {
        reportContent += "No raw API response data found or was empty.\n";
      }
      reportContent += "\n--- End of Report ---";

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showSnackBar('Could not determine storage directory.', Colors.red);
        return;
      }

      final fileName = 'diagnosis_report_${diagnosisId}.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(reportContent);

      final OpenResult result = await OpenFilex.open(file.path);

      if (result.type == ResultType.done) {
        _showSnackBar(
          'Report generated and saved to: ${file.path}',
          Colors.green,
        );
      } else {
        _showSnackBar('Failed to open report: ${result.message}', Colors.red);
      }
    } catch (e) {
      print('Error generating report: $e');
      _showSnackBar('Error generating report: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],

      appBar: AppBar(
        title: const Text('Diagnosis Review'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnosis Review',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Review recently submitted plant diagnoses and their AI predictions.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _diagnoses.isEmpty
                        ? const Center(
                          child: Text(
                            'No diagnoses found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 900
                                        ? 3
                                        : (MediaQuery.of(context).size.width >
                                                600
                                            ? 2
                                            : 1),
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _diagnoses.length,
                          itemBuilder: (context, index) {
                            final diag = _diagnoses[index];

                            String pestOrDisease =
                                diag['pestOrDisease'] ?? 'N/A';
                            double confidenceLevel =
                                (diag['confidenceLevel'] as num?)?.toDouble() ??
                                0.0;
                            String date =
                                diag['date'] != null
                                    ? DateTime.fromMillisecondsSinceEpoch(
                                      diag['date'],
                                    ).toLocal().toString().split(' ')[0]
                                    : 'N/A';
                            List<dynamic> recommendationsRaw =
                                diag['recommendations'] ?? [];
                            List<String> recommendations = List<String>.from(
                              recommendationsRaw.map((rec) => rec.toString()),
                            );
                            final dynamic rawApiData =
                                diag['rawApiResponse'];
                                 final dynamic input =
                                rawApiData['input'];
                                 final dynamic images =
                                input['images'];
                            // Access originalImageURL and get the correct ImageProvider
                            final String? originalImageString =
                                images[0] as String?;
                            final ImageProvider? imageProvider =
                                _getDiagnosisImageProvider(originalImageString);

                            var plantName =
                                diag['plantName'] ??
                                'Unknown Plant'; // Added plantName from diagnosis if available

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                          imageProvider !=
                                                  null // Use the determined imageProvider
                                              ? Image(
                                                image: imageProvider,
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      height: 120,
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                              : Container(
                                                // Fallback if no valid imageProvider
                                                height: 120,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported, // More descriptive icon
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      pestOrDisease,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Plant: $plantName',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Confidence: ${confidenceLevel.toStringAsFixed(2)}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Date: $date',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Using Flexible/Expanded to avoid layout issues in GridView
                                    Flexible(
                                      child: Text(
                                        'Recommendations: ${recommendations.join(', ')}', // Join for cleaner display
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.center,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _handleReview(diag['id']),
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View Report'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }
}
