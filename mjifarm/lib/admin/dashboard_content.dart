import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() { _isLoading = true; });
    try {
      // Total Users
      DataSnapshot userSnapshot = await _databaseRef.child('users').get();
      Map<dynamic, dynamic>? usersMap = userSnapshot.value as Map?;
      _totalUsers = usersMap?.length ?? 0;
      _activeFarmers = usersMap?.values.where((user) =>
          user['userRole'] != null &&
          (user['userRole'] as List).contains('farmer') &&
          user['status'] == 'active' // Assuming 'status' field in user
      ).length ?? 0;

      // Verified Experts
      DataSnapshot expertSnapshot = await _databaseRef.child('expert_profiles').get();
      Map<dynamic, dynamic>? expertsMap = expertSnapshot.value as Map?;
      _verifiedExperts = expertsMap?.values.where((expert) =>
          expert['isVerified'] == true
      ).length ?? 0;

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

    } catch (e) {
      print("Error fetching dashboard data: $e");
    } finally {
      setState(() { _isLoading = false; });
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
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardCard(context, 'Total Users', _totalUsers.toString(), Icons.people_alt, Colors.blue),
              _buildDashboardCard(context, 'Active Farmers', _activeFarmers.toString(), Icons.eco, Colors.green),
              _buildDashboardCard(context, 'Verified Experts', _verifiedExperts.toString(), Icons.verified_user, Colors.purple),
              _buildDashboardCard(context, 'Total Diagnoses', _totalDiagnoses.toString(), Icons.medical_services, Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'This dashboard provides a quick overview of key metrics in the Urban Farming Assistant App. More detailed reports can be generated in respective management sections.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

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
