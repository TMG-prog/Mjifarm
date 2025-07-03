import 'dart:io';
import 'dart:convert'; // For base64Decode

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart'; // For opening the generated file

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  User? _currentUser;
  bool _isLoading = true;

  // Data storage for the report
  Map<String, dynamic>? _userProfileData;
  Map<String, dynamic>? _farmerProfileData; // Assuming farmers are keyed by UID
  Map<String, dynamic>? _expertProfileData; // Assuming expert_profiles are keyed by UID
  List<Map<String, dynamic>> _userTasks = [];
  List<Map<String, dynamic>> _userDiagnoses = [];
  List<Map<String, dynamic>> _userGardens = []; // Data storage for gardens

  final String _vercelImageProxyBaseUrl = 'https://mjifarms-images.vercel.app/api'; // Your Vercel image proxy

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to view your report.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      _fetchAllUserData();
    }
  }

  Future<void> _fetchAllUserData() async {
    setState(() {
      _isLoading = true;
    });

    final userId = _currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('User not logged in.', Colors.red);
      return;
    }

    try {
      // 1. Fetch User Profile Data
      final userProfileRef = FirebaseDatabase.instance.ref('users/$userId');
      final userProfileSnapshot = await userProfileRef.once();
      if (userProfileSnapshot.snapshot.value != null && userProfileSnapshot.snapshot.value is Map) {
        _userProfileData = Map<String, dynamic>.from(userProfileSnapshot.snapshot.value as Map);
      }

      // 2. Fetch Farmer Profile Data (if exists)
      final farmerProfileRef = FirebaseDatabase.instance.ref('farmers/$userId');
      final farmerProfileSnapshot = await farmerProfileRef.once();
      if (farmerProfileSnapshot.snapshot.value != null && farmerProfileSnapshot.snapshot.value is Map) {
        _farmerProfileData = Map<String, dynamic>.from(farmerProfileSnapshot.snapshot.value as Map);
      }

      // 3. Fetch Expert Profile Data (if exists)
      final expertProfileRef = FirebaseDatabase.instance.ref('expert_profiles/$userId');
      final expertProfileSnapshot = await expertProfileRef.once();
      if (expertProfileSnapshot.snapshot.value != null && expertProfileSnapshot.snapshot.value is Map) {
        _expertProfileData = Map<String, dynamic>.from(expertProfileSnapshot.snapshot.value as Map);
      }

      // 4. Fetch User Tasks (Corrected for your data structure and rules)
      final tasksRef = FirebaseDatabase.instance.ref('tasks/$userId');
      final tasksEvent = await tasksRef.once();
      final tasksSnapshot = tasksEvent.snapshot;

      List<Map<String, dynamic>> fetchedTasks = [];
      if (tasksSnapshot.value != null && tasksSnapshot.value is Map) {
        (tasksSnapshot.value as Map).forEach((key, value) {
          if (value is Map) {
            fetchedTasks.add({'id': key, ...Map<String, dynamic>.from(value)});
          }
        });
      }
      _userTasks = fetchedTasks;

      // 5. Fetch User Diagnoses (as previously implemented)
      final userDiagnosesRef = FirebaseDatabase.instance.ref('users/$userId/diagnoses');
      final userDiagnosesEvent = await userDiagnosesRef.once();
      final userDiagnosesSnapshot = userDiagnosesEvent.snapshot;

      List<Map<String, dynamic>> fetchedDiagnoses = [];
      if (userDiagnosesSnapshot.value != null && userDiagnosesSnapshot.value is Map) {
        final Map<dynamic, dynamic> userDiagnosisRefsMap = userDiagnosesSnapshot.value as Map;
        for (final entry in userDiagnosisRefsMap.entries) {
          final diagnosisId = entry.key;
          final diagnosisRefData = Map<String, dynamic>.from(entry.value);
          final cropLogId = diagnosisRefData['cropLogId'];

          if (cropLogId != null) {
            final fullDiagnosisRef = FirebaseDatabase.instance.ref('crop_logs/$cropLogId/diagnoses/$diagnosisId');
            final fullDiagnosisEvent = await fullDiagnosisRef.once();
            final fullDiagnosisSnapshot = fullDiagnosisEvent.snapshot;

            if (fullDiagnosisSnapshot.value != null && fullDiagnosisSnapshot.value is Map) {
              final Map<String, dynamic> fullDiagnosisData = Map<String, dynamic>.from(fullDiagnosisSnapshot.value as Map);
              fetchedDiagnoses.add({
                'id': diagnosisId,
                'cropLogId': cropLogId,
                ...fullDiagnosisData,
              });
            }
          }
        }
      }
      _userDiagnoses = fetchedDiagnoses;

      // 6. Fetch User Gardens and their Plants
      final gardensRef = FirebaseDatabase.instance.ref('gardens');
      final gardensEvent = await gardensRef.orderByChild('userID').equalTo(userId).once();
      final gardensSnapshot = gardensEvent.snapshot;

      List<Map<String, dynamic>> fetchedGardensData = [];
      if (gardensSnapshot.value != null && gardensSnapshot.value is Map) {
        final gardensMap = gardensSnapshot.value as Map;
        for (final gardenEntry in gardensMap.entries) {
          final gardenId = gardenEntry.key;
          final gardenData = Map<String, dynamic>.from(gardenEntry.value);
          final gardenName = gardenData['name'] ?? 'Unnamed Garden';

          // Fetch plants for this garden
          final plantsRef = FirebaseDatabase.instance.ref('gardens/$gardenId/plants');
          final plantsEvent = await plantsRef.once();
          final plantsSnapshot = plantsEvent.snapshot;

          List<Map<String, dynamic>> fetchedPlants = [];
          if (plantsSnapshot.value != null && plantsSnapshot.value is Map) {
            (plantsSnapshot.value as Map).forEach((plantKey, plantValue) {
              if (plantValue is Map) {
                fetchedPlants.add({'id': plantKey, ...Map<String, dynamic>.from(plantValue)});
              }
            });
          }
          fetchedGardensData.add({
            'id': gardenId,
            'name': gardenName,
            'plants': fetchedPlants, // Nested plants under each garden
          });
        }
      }
      _userGardens = fetchedGardensData;


      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching all user data: $e");
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching your data: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: color,
      ),
    );
  }

  // Helper function to get the appropriate ImageProvider (Network via proxy, or Memory)
  ImageProvider? _getDiagnosisImageProvider(String? rawPlantIdImageUrl) {
    if (rawPlantIdImageUrl == null || rawPlantIdImageUrl.isEmpty) {
      return null;
    }

    if (rawPlantIdImageUrl.startsWith('http://') || rawPlantIdImageUrl.startsWith('https://')) {
      final Uri proxyUri = Uri.parse(_vercelImageProxyBaseUrl).replace(
        queryParameters: {'url': rawPlantIdImageUrl},
      );
      return NetworkImage(proxyUri.toString());
    } else {
      try {
        final String base64String = rawPlantIdImageUrl.contains(',') ? rawPlantIdImageUrl.split(',').last : rawPlantIdImageUrl;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print("Error decoding Base64 image for diagnosis: $e");
        return null;
      }
    }
  }

  Future<void> _generateReport() async {
    if (_currentUser == null) {
      _showSnackBar('Please log in to generate a report.', Colors.orange);
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackBar('Storage permission denied. Cannot save report.', Colors.red);
          return;
        }
      }
    }

    try {
      String reportContent = '--- Comprehensive User Report ---\n\n';
      reportContent += 'Generated on: ${DateTime.now().toLocal().toIso8601String()}\n';
      reportContent += 'User ID: ${_currentUser?.uid ?? 'N/A'}\n\n';

      // --- User Profile Section ---
      reportContent += '--- User Profile ---\n';
      if (_userProfileData != null) {
        _userProfileData!.forEach((key, value) {
          // Truncate base64 image strings if found
          if ((key == 'imageBase64' || key == 'profilePicture') && value is String) {
            String truncatedValue = value.length > 500 ? '${value.substring(0, 500)}... (truncated)' : value;
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $truncatedValue\n';
          } else {
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $value\n'; // Format key
          }
        });
      } else {
        reportContent += 'No user profile data found.\n';
      }
      reportContent += '\n';

      // --- Farmer Profile Section ---
      reportContent += '--- Farmer Profile ---\n';
      if (_farmerProfileData != null) {
        _farmerProfileData!.forEach((key, value) {
          // Truncate base64 image strings if found
          if ((key == 'image' || key == 'profilePicture') && value is String) {
            String truncatedValue = value.length > 500 ? '${value.substring(0, 500)}... (truncated)' : value;
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $truncatedValue\n';
          } else {
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $value\n';
          }
        });
      } else {
        reportContent += 'No farmer profile data found.\n';
      }
      reportContent += '\n';

      // --- Expert Profile Section ---
      reportContent += '--- Expert Profile ---\n';
      if (_expertProfileData != null) {
        _expertProfileData!.forEach((key, value) {
          // Truncate base64 image strings if found
          if ((key == 'image' || key == 'profilePicture') && value is String) {
            String truncatedValue = value.length > 500 ? '${value.substring(0, 500)}... (truncated)' : value;
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $truncatedValue\n';
          } else {
            reportContent += '${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $value\n';
          }
        });
      } else {
        reportContent += 'No expert profile data found.\n';
      }
      reportContent += '\n';

      // --- Gardens Section ---
      reportContent += '--- User Gardens ---\n';
      if (_userGardens.isEmpty) {
        reportContent += 'No gardens found for this user.\n';
      } else {
        for (int i = 0; i < _userGardens.length; i++) {
          final garden = _userGardens[i];
          reportContent += 'Garden ${i + 1} (ID: ${garden['id'] ?? 'N/A'}):\n';
          reportContent += '  Name: ${garden['name'] ?? 'Unnamed Garden'}\n';
          
          List<Map<String, dynamic>> plants = List<Map<String, dynamic>>.from(garden['plants'] ?? []);
          if (plants.isNotEmpty) {
            reportContent += '  Plants in this Garden:\n';
            for (int j = 0; j < plants.length; j++) {
              final plant = plants[j];
              reportContent += '    Plant ${j + 1} (ID: ${plant['id'] ?? 'N/A'}):\n';
              reportContent += '      Name: ${plant['name'] ?? 'N/A'}\n';
              reportContent += '      Category: ${plant['category'] ?? 'N/A'}\n';
              reportContent += '      Container: ${plant['container'] ?? 'N/A'}\n';
              reportContent += '      Planting Date: ${plant['plantingDate'] ?? 'N/A'}\n';
              reportContent += '      Maturity Date: ${plant['maturityDate'] ?? 'N/A'}\n';
              // If there's an imageBase64 for plants, you can truncate it here too
              if (plant['imageBase64'] is String) {
                String truncatedPlantImage = plant['imageBase64'].length > 500 ? '${plant['imageBase64'].substring(0, 500)}... (truncated)' : plant['imageBase64'];
                reportContent += '      Image (Base64): $truncatedPlantImage\n';
              }
            }
          } else {
            reportContent += '  No plants in this garden.\n';
          }
          reportContent += '\n';
        }
      }
      reportContent += '\n';


      // --- Tasks Section ---
      reportContent += '--- User Tasks ---\n';
      if (_userTasks.isEmpty) {
        reportContent += 'No tasks found for this user.\n';
      } else {
        for (int i = 0; i < _userTasks.length; i++) {
          final task = _userTasks[i];
          reportContent += 'Task ${i + 1} (ID: ${task['id'] ?? 'N/A'}):\n';
          task.forEach((key, value) {
            if (key != 'id') { // Don't repeat the ID
              // Apply truncation for tasks if they also store base64 images
              if ((key == 'imageBase64' || key == 'photo') && value is String) {
                 String truncatedValue = value.length > 500 ? '${value.substring(0, 500)}... (truncated)' : value;
                 reportContent += '  ${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $truncatedValue\n';
              } else {
                reportContent += '  ${key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}: $value\n'; // Format key
              }
            }
          });
          reportContent += '\n';
        }
      }
      reportContent += '\n';

      // --- Diagnoses Section ---
      reportContent += '--- User Diagnoses ---\n';
      if (_userDiagnoses.isEmpty) {
        reportContent += 'No diagnosis records found for this user.\n';
      } else {
        for (int i = 0; i < _userDiagnoses.length; i++) {
          final diag = _userDiagnoses[i];
          reportContent += 'Diagnosis ${i + 1} (ID: ${diag['id'] ?? 'N/A'}):\n';
          reportContent += '  Crop Log ID: ${diag['cropLogId'] ?? 'N/A'}\n';
          reportContent += '  AI Result: ${diag['pestOrDisease'] ?? 'Unknown Issue'}\n';
          reportContent += '  Confidence: ${(diag['confidenceLevel'] as num?)?.toStringAsFixed(1) ?? '0.0'}%\n';
          reportContent += '  Date: ${diag['date'] != null ? DateTime.fromMillisecondsSinceEpoch(diag['date']).toLocal().toString().split(' ')[0] : 'N/A'}\n';
          reportContent += '  Status: ${diag['reviewStatus'] == 'pending_expert_review' ? 'Pending Review' : (diag['reviewStatus'] == 'reviewed' ? 'Reviewed' : 'Not Reviewed')}\n';

          // Truncate diagnosis image if it's stored directly in diagnosis record (e.g., 'capturedImageBase64')
          if (diag['capturedImageBase64'] is String) {
            String truncatedDiagImage = diag['capturedImageBase64'].length > 500 ? '${diag['capturedImageBase64'].substring(0, 500)}... (truncated)' : diag['capturedImageBase64'];
            reportContent += '  Captured Image (Base64): $truncatedDiagImage\n';
          }


          List<String> recommendations = List<String>.from(diag['recommendations'] ?? []);
          reportContent += '  Recommendations:\n';
          if (recommendations.isNotEmpty) {
            for (int j = 0; j < recommendations.length; j++) {
              reportContent += '    ${j + 1}. ${recommendations[j]}\n';
            }
          } else {
            reportContent += '    No specific recommendations.\n';
          }

          List<String> relatedImages = List<String>.from(diag['relatedDiseaseImages'] ?? []);
          reportContent += '  Related Images (URLs):\n';
          if (relatedImages.isNotEmpty) {
            for (int j = 0; j < relatedImages.length; j++) {
              final String proxiedImageUrl = (relatedImages[j].startsWith('http://') || relatedImages[j].startsWith('https://'))
                  ? Uri.parse(_vercelImageProxyBaseUrl).replace(queryParameters: {'url': relatedImages[j]}).toString()
                  : 'N/A (not a URL)';
              reportContent += '    ${j + 1}. $proxiedImageUrl\n';
            }
          } else {
            reportContent += '    No related images.\n';
          }
          reportContent += '\n';
        }
      }

      reportContent += '--- End of Report ---\n';

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showSnackBar('Could not determine storage directory.', Colors.red);
        return;
      }
      
      final fileName = 'user_comprehensive_report_${_currentUser?.uid ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(reportContent);

      final OpenResult result = await OpenFilex.open(file.path);

      if (result.type == ResultType.done) {
        _showSnackBar('Report generated and saved to: ${file.path}', Colors.green);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Comprehensive Report'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(
                  child: Text(
                    'Please log in to view your comprehensive report.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Comprehensive Data Overview',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This report consolidates your profile information, tasks, and plant diagnoses.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      // Display a summary or just the button
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Profile Status: ${_userProfileData != null ? 'Loaded' : 'Not Found'}',
                              style: TextStyle(color: _userProfileData != null ? Colors.green : Colors.red),
                            ),
                            Text(
                              'Farmer Profile Status: ${_farmerProfileData != null ? 'Loaded' : 'Not Found'}',
                              style: TextStyle(color: _farmerProfileData != null ? Colors.green : Colors.grey),
                            ),
                            Text(
                              'Expert Profile Status: ${_expertProfileData != null ? 'Loaded' : 'Not Found'}',
                              style: TextStyle(color: _expertProfileData != null ? Colors.green : Colors.grey),
                            ),
                            Text(
                              'Gardens Found: ${_userGardens.length}',
                              style: TextStyle(color: _userGardens.isNotEmpty ? Colors.green : Colors.grey),
                            ),
                            Text(
                              'Tasks Found: ${_userTasks.length}',
                              style: TextStyle(color: _userTasks.isNotEmpty ? Colors.green : Colors.grey),
                            ),
                            Text(
                              'Diagnoses Found: ${_userDiagnoses.length}',
                              style: TextStyle(color: _userDiagnoses.isNotEmpty ? Colors.green : Colors.grey),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateReport,
                              icon: const Icon(Icons.download),
                              label: const Text('Download Comprehensive Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                textStyle: const TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}