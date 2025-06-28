import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // Still needed if you use kIsWeb elsewhere, but not for ReportDownloader instantiation here.

// --- SIMPLIFIED IMPORT ---
// Only import the single entry point file for ReportDownloader.
// This file contains the abstract class and its factory constructor.
import 'package:mjifarm/services/report_downloader.dart';
// --- END SIMPLIFIED IMPORT ---

class DiagnosisReviewContent extends StatefulWidget {
  const DiagnosisReviewContent({super.key});

  @override
  State<DiagnosisReviewContent> createState() => _DiagnosisReviewContentState();
}

class _DiagnosisReviewContentState extends State<DiagnosisReviewContent> {
  late DatabaseReference _cropLogsRef;
  List<Map<String, dynamic>> _diagnoses = [];
  bool _isLoading = true;

  final String _vercelImageProxyBaseUrl =
      'https://mjifarms-images.vercel.app/api';

  // Declare the ReportDownloader instance
  late ReportDownloader _reportDownloader;

  @override
  void initState() {
    super.initState();
    _cropLogsRef = FirebaseDatabase.instance.ref('crop_logs');
    _listenToDiagnoses();

    // --- KEY CHANGE HERE ---
    // Instantiate ReportDownloader using its factory constructor.
    // The factory in 'report_downloader.dart' internally handles
    // picking the correct platform implementation.
    _reportDownloader = ReportDownloader(context: context);
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: color,
        ),
      );
    }
  }

  ImageProvider? _getDiagnosisImageProvider(String? rawPlantIdImageUrl) {
    if (rawPlantIdImageUrl == null || rawPlantIdImageUrl.isEmpty) {
      return null;
    }

    if (rawPlantIdImageUrl.startsWith('http://') ||
        rawPlantIdImageUrl.startsWith('https://')) {
      final Uri proxyUri = Uri.parse(_vercelImageProxyBaseUrl).replace(
        queryParameters: {
          'url': rawPlantIdImageUrl,
        },
      );
      return NetworkImage(proxyUri.toString());
    } else {
      try {
        final String base64String =
            rawPlantIdImageUrl.contains(',')
                ? rawPlantIdImageUrl.split(',').last
                : rawPlantIdImageUrl;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print("Error decoding Base64 image for diagnosis: $e");
        return null;
      }
    }
  }

  Future<void> _handleReview(String diagnosisId) async {
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

    List<String> rawApiResponse = [];
    final dynamic rawApiData = specificDiagnosis['rawApiResponse'];
    if (rawApiData != null) {
      if (rawApiData is Map) {
        rawApiResponse = List<String>.from(
          rawApiData.values.map((e) => e.toString()),
        );
      } else if (rawApiData is Iterable) {
        rawApiResponse = List<String>.from(rawApiData.map((e) => e.toString()));
      }
    }

    List<String> relatedDiseaseImages = [];
    final dynamic relatedImagesData =
        specificDiagnosis['relatedDiseasesImages'];
    if (relatedImagesData != null) {
      if (relatedImagesData is Iterable) {
        relatedDiseaseImages = List<String>.from(
          relatedImagesData.map((e) => e.toString()),
        );
      } else if (relatedImagesData is String &&
          (relatedImagesData.startsWith('http') ||
              relatedImagesData.startsWith('data:image'))) {
        relatedDiseaseImages = [relatedImagesData];
      }
    }

    String diagnosisResult =
        specificDiagnosis['pestOrDisease']?.toString() ?? 'N/A';

    List<String> recommendations = List<String>.from(
      recommendationsRaw.map((rec) => rec.toString()),
    );

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
      for (int i = 0; i < relatedDiseaseImages.length; i++) {
        final String proxiedImageUrl =
            (relatedDiseaseImages[i].startsWith('http://') ||
                    relatedDiseaseImages[i].startsWith('https://'))
                ? Uri.parse(_vercelImageProxyBaseUrl)
                    .replace(queryParameters: {'url': relatedDiseaseImages[i]})
                    .toString()
                : 'N/A (not a URL)';
        reportContent += "${i + 1}. $proxiedImageUrl\n";
      }
    } else {
      reportContent += "No related images found.\n";
    }
    reportContent += "\n";

    reportContent += "Raw API Response:\n";
    if (rawApiResponse.isNotEmpty) {
      reportContent += rawApiResponse.join('\n');
    } else {
      reportContent += "No raw API response data found or was empty.\n";
    }
    reportContent += "\n--- End of Report ---";

    final fileName = 'diagnosis_report_${diagnosisId}.txt';

    // Use the platform-specific downloader instance
    await _reportDownloader.downloadReport(fileName, reportContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      appBar: AppBar(
        title: const Text('Diagnosis Review'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnosis Review',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 900
                                ? 3
                                : (MediaQuery.of(context).size.width > 600
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
                            String date = diag['date'] != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                        diag['date'],
                                      ).toLocal().toString().split(' ')[0]
                                : 'N/A';
                            List<dynamic> recommendationsRaw =
                                diag['recommendations'] ?? [];
                            List<String> recommendations = List<String>.from(
                              recommendationsRaw.map((rec) => rec.toString()),
                            );

                            final dynamic rawApiData = diag['rawApiResponse'];
                            String? originalImageString;
                            if (rawApiData is Map &&
                                rawApiData['input'] is Map &&
                                rawApiData['input']['images'] is List &&
                                rawApiData['input']['images'].isNotEmpty) {
                              originalImageString =
                                  rawApiData['input']['images'][0] as String?;
                            }

                            final ImageProvider? imageProvider =
                                _getDiagnosisImageProvider(originalImageString);

                            var plantName =
                                diag['plantName'] ?? 'Unknown Plant';

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
                                      child: imageProvider != null
                                          ? Image(
                                              image: imageProvider,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
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
                                              height: 120,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      pestOrDisease,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Plant: $plantName',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                    Text(
                                      'Confidence: ${confidenceLevel.toStringAsFixed(2)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                    Text(
                                      'Date: $date',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        'Recommendations: ${recommendations.join(', ')}',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.center,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _handleReview(diag['id']),
                                        icon: const Icon(Icons.download),
                                        label: const Text('Download Report'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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