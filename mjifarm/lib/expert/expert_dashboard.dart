import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // If you need current user info
import 'package:firebase_database/firebase_database.dart'; // To fetch diagnoses

class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  User? _currentUser;
  int _pendingDiagnosesCount = 0;
  bool _isLoading = true;
  final DatabaseReference _cropLogsRef = FirebaseDatabase.instance.ref('crop_logs');

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchPendingDiagnosesCount();
  }

  Future<void> _fetchPendingDiagnosesCount() async {
    setState(() { _isLoading = true; });
    int count = 0;
    try {
      DataSnapshot cropLogsSnapshot = await _cropLogsRef.get();
      if (cropLogsSnapshot.exists && cropLogsSnapshot.value is Map) {
        Map<dynamic, dynamic> cropLogsMap = cropLogsSnapshot.value as Map<dynamic, dynamic>;
        cropLogsMap.forEach((cropLogId, cropLogValue) {
          if (cropLogValue is Map && cropLogValue['diagnoses'] is Map) {
            Map<dynamic, dynamic> diagnosesMap = cropLogValue['diagnoses'];
            diagnosesMap.forEach((diagId, diagValue) {
              // Assuming a 'status' field in diagnosis, e.g., 'pending', 'reviewed'
              if (diagValue is Map && diagValue['status'] == 'pending') {
                count++;
              }
            });
          }
        });
      }
    } catch (e) {
      print("Error fetching pending diagnoses count: $e");
    } finally {
      setState(() {
        _pendingDiagnosesCount = count;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return  Scaffold(
        appBar: AppBar(title: Text('Expert Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_currentUser?.displayName ?? _currentUser?.email ?? 'Expert'}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Expert Panel',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: Text('Pending Diagnoses ($_pendingDiagnosesCount)'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to PendingDiagnosesScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Pending Diagnoses...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to ExpertProfileScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to My Profile...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Consultation History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to ExpertHistoryScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to History...')),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expert Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildExpertCard(
                  context,
                  'Pending Diagnoses',
                  _pendingDiagnosesCount.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                  () {
                    // TODO: Navigate to PendingDiagnosesScreen
                  },
                ),
                _buildExpertCard(
                  context,
                  'My Profile',
                  'Manage your info',
                  Icons.person,
                  Colors.blue,
                  () {
                    // TODO: Navigate to ExpertProfileScreen
                  },
                ),
                _buildExpertCard(
                  context,
                  'View History',
                  'Past consultations',
                  Icons.history,
                  Colors.teal,
                  () {
                    // TODO: Navigate to ExpertHistoryScreen
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to your expert dashboard. Here you can find an overview of new plant diagnosis requests and access your consultation tools.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
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
      ),
    );
  }
}
