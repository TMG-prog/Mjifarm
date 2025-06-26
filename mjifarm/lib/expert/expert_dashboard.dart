import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import "../expert_features/expert_chat_list.dart";
import '../expert_features/expert_articles_management.dart';
import 'package:mjifarm/auth_gate.dart';

class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  User? _currentUser;
  int _pendingDiagnosesCount = 0;
  bool _isLoading = true;
  final DatabaseReference _cropLogsRef = FirebaseDatabase.instance.ref(
    'crop_logs',
  );

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchPendingDiagnosesCount();
  }

  Future<void> _fetchPendingDiagnosesCount() async {
    setState(() {
      _isLoading = true;
    });
    int count = 0;
    try {
      DataSnapshot cropLogsSnapshot = await _cropLogsRef.get();
      if (cropLogsSnapshot.exists && cropLogsSnapshot.value is Map) {
        Map<dynamic, dynamic> cropLogsMap =
            cropLogsSnapshot.value as Map<dynamic, dynamic>;
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
      print("Error fetching  diagnoses count: $e");
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
      return Scaffold(
        appBar: AppBar(title: const Text('Expert Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Dashboard'),

        actions: [
          IconButton(
            //sign out button
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthGate()),
              );
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
                  const SnackBar(
                    content: Text('Navigating to Pending Diagnoses...'),
                  ),
                );
              },
            ),
            // NEW: Chat List Tile in Drawer
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('My Chats'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExpertChatListScreen(),
                  ),
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
              title: const Text('Create Articles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateArticleScreen(),
                  ),
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
              crossAxisCount:
                  MediaQuery.of(context).size.width > 600
                      ? 3
                      : (MediaQuery.of(context).size.width > 300 ? 2 : 1),
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
                // NEW: Chat Card
                _buildExpertCard(
                  context,
                  'My Chats',
                  'Active conversations', // You could fetch actual unread count if desired
                  Icons.chat,
                  Colors.purple, // Choose a suitable color
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExpertChatListScreen(),
                      ),
                    );
                  },
                ),
                _buildExpertCard(
                  context,
                  'My Profile',
                  'Manage your info',
                  Icons.person,
                  Colors.blue,
                  () {},
                ),
                _buildExpertCard(
                  context,
                  'Create Artcles',
                  'Past consultations',
                  Icons.history,
                  Colors.teal,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateArticleScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to your expert dashboard. Here you can find an overview of your consultation tools and Create Your Own Articles.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.green.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
