import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference
// Needed for potential UID checks

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  int _totalUsers = 0;
  int _activeFarmers = 0;
  int _verifiedExperts = 0;
  int _totalDiagnoses = 0;
  List<Map<dynamic, dynamic>> _pendingExpertApplications = []; // New list for applications
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _listenToPendingExpertApplications(); // Start listening for real-time updates
  }

  // New method to listen for real-time updates on expert applications
  void _listenToPendingExpertApplications() {
    _databaseRef.child('expert_applications').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> applicationsMap = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<dynamic, dynamic>> fetchedApplications = [];
        applicationsMap.forEach((key, value) {
          fetchedApplications.add({'uid': key, ...value});
        });
        setState(() {
          _pendingExpertApplications = fetchedApplications;
        });
      } else {
        setState(() {
          _pendingExpertApplications = [];
        });
      }
    }, onError: (error) {
      print("Error listening to expert applications: $error");
    });
  }


  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Total Users
      DataSnapshot userSnapshot = await _databaseRef.child('users').get();
      Map<dynamic, dynamic>? usersMap = userSnapshot.value as Map?;
      _totalUsers = usersMap?.length ?? 0;
      _activeFarmers = usersMap?.values.where((user) =>
              user['userRole'] != null &&
              (user['userRole'] as List).contains('farmer') &&
              user['status'] == 'active' // Assuming 'status' field in user
          ).length ??
          0;

      // Verified Experts
      DataSnapshot expertSnapshot =
          await _databaseRef.child('expert_profiles').get();
      Map<dynamic, dynamic>? expertsMap = expertSnapshot.value as Map?;
      _verifiedExperts =
          expertsMap?.values.where((expert) => expert['isVerified'] == true).length ?? 0;

      // Total Diagnoses (Requires iterating through crop_logs and subcollections)
      _totalDiagnoses = 0;
      DataSnapshot cropLogsSnapshot = await _databaseRef.child('crop_logs').get();
      Map<dynamic, dynamic>? cropLogsMap = cropLogsSnapshot.value as Map?;
      if (cropLogsMap != null) {
        for (var cropLogEntry in cropLogsMap.values) {
          if (cropLogEntry['diagnoses'] != null) {
            _totalDiagnoses += (cropLogEntry['diagnoses'] as Map).length;
          }
        }
      }

      // No need to fetch applications here, as _listenToPendingExpertApplications() handles it
    } catch (e) {
      print("Error fetching dashboard data: $e");
      // Optionally show a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to approve an expert application
  Future<void> _approveApplication(Map<dynamic, dynamic> application) async {
    final String applicantUid = application['uid'];
    final DatabaseReference expertProfilesRef = FirebaseDatabase.instance.ref('expert_profiles');
    final DatabaseReference applicationsRef = FirebaseDatabase.instance.ref('expert_applications');

    try {
      // 1. Move/Copy to expert_profiles
      await expertProfilesRef.child(applicantUid).set({
        'uid': applicantUid,
        'displayName': application['displayName'],
        'email': application['email'],
        'expertise': application['expertise'],
        'experience': application['experience'],
        'contactEmail': application['contactEmail'],
        'contactPhone': application['contactPhone'],
        'isVerified': true, // Mark as verified upon approval
        'approvedOn': ServerValue.timestamp, // Record approval timestamp
        // Add any other fields relevant for an expert profile
      });

      // 2. Remove from expert_applications
      await applicationsRef.child(applicantUid).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expert approved successfully!')),
      );
    } catch (e) {
      print('Error approving expert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve expert: $e')),
      );
    }
  }

  // Method to reject an expert application
  Future<void> _rejectApplication(String applicantUid) async {
    final DatabaseReference applicationsRef = FirebaseDatabase.instance.ref('expert_applications');
    try {
      // 1. Remove from expert_applications
      await applicationsRef.child(applicantUid).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expert application rejected.')),
      );
    } catch (e) {
      print('Error rejecting expert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject application: $e')),
      );
    }
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
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 4
                : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardCard(
                  context, 'Total Users', _totalUsers.toString(), Icons.people_alt, Colors.blue),
              _buildDashboardCard(
                  context, 'Active Farmers', _activeFarmers.toString(), Icons.eco, Colors.green),
              _buildDashboardCard(context, 'Verified Experts', _verifiedExperts.toString(),
                  Icons.verified_user, Colors.purple),
              _buildDashboardCard(context, 'Total Diagnoses', _totalDiagnoses.toString(),
                  Icons.medical_services, Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'This dashboard provides a quick overview of key metrics in the Urban Farming Assistant App. More detailed reports can be generated in respective management sections.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32), // Spacer before the new section

          // NEW: Pending Expert Applications Section
          Text(
            'Pending Expert Applications (${_pendingExpertApplications.length})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
          ),
          const SizedBox(height: 16),
          _pendingExpertApplications.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No pending expert applications at the moment.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingExpertApplications.length,
                  itemBuilder: (context, index) {
                    final application = _pendingExpertApplications[index];
                    final String applicantUid = application['uid'] ?? 'N/A';
                    final String displayName = application['displayName'] ?? 'Unknown User';
                    final String email = application['email'] ?? 'No Email';
                    final String expertise = application['expertise'] ?? 'N/A';
                    final String experience = application['experience'] ?? 'N/A';
                    final String status = application['status'] ?? 'pending';

                    final int? timestamp = application['timestamp'];
                    final String formattedDate = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal().toString().split('.')[0]
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Applicant: $displayName ($email)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('UID: $applicantUid', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text('Expertise: $expertise'),
                            Text(
                              'Experience: ${experience.substring(0, experience.length.clamp(0, 150))}${experience.length > 150 ? '...' : ''}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            Text('Status: $status',
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: status == 'pending' ? Colors.orange : Colors.green)),
                            Text('Applied On: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _approveApplication(application),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _rejectApplication(applicantUid),
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ],
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

  // Existing _buildDashboardCard method unchanged
  Widget _buildDashboardCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}