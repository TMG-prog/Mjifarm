import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference

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
    _cropLogsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> fetchedDiagnoses = [];
      if (data != null && data is Map) {
        data.forEach((cropLogId, cropLogValue) {
          if (cropLogValue is Map && cropLogValue['diagnoses'] != null && cropLogValue['diagnoses'] is Map) {
            Map<dynamic, dynamic> diagnosesMap = cropLogValue['diagnoses'];
            diagnosesMap.forEach((diagId, diagValue) {
              if (diagValue is Map) {
                fetchedDiagnoses.add({'id': diagId, 'cropLogId': cropLogId, ...Map<String, dynamic>.from(diagValue)});
              }
            });
          }
        });
      }
      setState(() {
        _diagnoses = fetchedDiagnoses;
        _isLoading = false;
      });
    }, onError: (error) {
      print("Error listening to diagnoses: $error");
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Error fetching diagnoses: $error", Colors.red);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), backgroundColor: color),
    );
  }

  void _handleReview(String diagnosisId) {
    _showSnackBar('Reviewing diagnosis $diagnosisId. (Open detailed view in future)', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          _diagnoses.isEmpty
              ? const Center(
                  child: Text('No diagnoses found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _diagnoses.length,
                  itemBuilder: (context, index) {
                    final diag = _diagnoses[index];
                    String plantName = diag['plantName'] ?? 'Unknown Plant'; // Added from schema
                    String pestOrDisease = diag['pestOrDisease'] ?? 'N/A';
                    double confidenceLevel = (diag['confidenceLevel'] as num?)?.toDouble() ?? 0.0;
                    String date = diag['date'] != null ? DateTime.fromMillisecondsSinceEpoch(diag['date']).toLocal().toString().split(' ')[0] : 'N/A';
                    List<dynamic> recommendationsRaw = diag['recommendations'] ?? [];
                    List<String> recommendations = List<String>.from(recommendationsRaw.map((rec) => rec.toString()));
                    String originalImageURL = diag['originalImageURL'] ?? 'https://placehold.co/400x200/AAAAAA/FFFFFF?text=No+Image';

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                originalImageURL,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pestOrDisease,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plant: $plantName',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                            Text(
                              'Confidence: ${confidenceLevel.toStringAsFixed(2)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Date: $date',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                'Recommendations: ${recommendations.join(' ')}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleReview(diag['id']),
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }
}
