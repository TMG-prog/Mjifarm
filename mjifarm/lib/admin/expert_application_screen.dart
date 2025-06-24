import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth if needed elsewhere

class AdminExpertApplicationsScreen extends StatefulWidget {
  const AdminExpertApplicationsScreen({super.key});

  @override
  State<AdminExpertApplicationsScreen> createState() => _AdminExpertApplicationsScreenState();
}

class _AdminExpertApplicationsScreenState extends State<AdminExpertApplicationsScreen> {
  final DatabaseReference _applicationsRef =
      FirebaseDatabase.instance.ref('expert_applications');
  final DatabaseReference _expertProfilesRef =
      FirebaseDatabase.instance.ref('expert_profiles');
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref('users'); // Reference to the users node

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Applications (Admin)'),
        backgroundColor: Colors.redAccent, // Distinct color for admin view
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _applicationsRef.onValue, // Listen for real-time changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No pending expert applications.'));
          }

          // Data is a Map<String, dynamic> where key is applicant UID
          final Map<dynamic, dynamic> applicationsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          final List<Map<dynamic, dynamic>> applications = [];
          applicationsMap.forEach((key, value) {
            // Add the UID as part of the application data for easier access
            applications.add({'uid': key, ...value});
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final String applicantUid = application['uid'] ?? 'N/A';
              final String displayName = application['displayName'] ?? 'Unknown User';
              final String email = application['email'] ?? 'No Email';
              final String expertise = application['expertise'] ?? 'N/A';
              final String experience = application['experience'] ?? 'N/A';
              final String status = application['status'] ?? 'pending';
              final String contactEmail = application['contactEmail'] ?? 'N/A';
              final String contactPhone = application['contactPhone'] ?? 'N/A';


              // Format timestamp if available
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
                      Text('Applicant: $displayName ($email)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('UID: $applicantUid', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Expertise: $expertise'),
                      Text('Experience: ${experience.substring(0, experience.length.clamp(0, 100))}...', style: const TextStyle(color: Colors.black87)), // Show a snippet
                      Text('Status: $status', style: TextStyle(fontStyle: FontStyle.italic, color: status == 'pending' ? Colors.orange : Colors.green)),
                      Text('Applied On: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _approveApplication(applicantUid, application), // Pass UID and full data
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _rejectApplication(applicantUid), // Pass only UID
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
          );
        },
      ),
    );
  }

  Future<void> _approveApplication(
      String applicantUid, Map<dynamic, dynamic> applicationData) async {
    try {
      // 1. Create the Expert Profile
      final newExpertProfileData = {
        'userID': applicantUid, // Use applicantUid as userID
        'name': applicationData['displayName'], // Map displayName to name
        'email': applicationData['email'],
        'expertiseArea': "${applicationData['expertise'] ?? ''}. ${applicationData['experience'] ?? ''}".trim(),
        'isVerified': true, // Set to true upon approval
        'contactHandle': applicationData['contactEmail'] ?? applicationData['contactPhone'] ?? '',
        'approvedOn': ServerValue.timestamp, // Keep this if you want to track approval time
      };

      await _expertProfilesRef.child(applicantUid).set(newExpertProfileData);
      print('Expert profile created for $applicantUid');

      // 2. Set the isExpert flag to true for the user in the 'users' node
      await _usersRef.child(applicantUid).update({
        'isExpert': true, // Set the isExpert boolean flag
      });
      print('isExpert flag set to true for $applicantUid');

      // 3. (Optional) Update userRole to include "farmer" if that's your consistent model
      //    We are NOT putting 'expert' into userRole because 'isExpert' is the source of truth.
      DataSnapshot userRoleSnapshot = await _usersRef.child(applicantUid).child('userRole').get();
      List<dynamic> currentUserRoles = [];
      if (userRoleSnapshot.exists && userRoleSnapshot.value is List) {
        currentUserRoles = List<dynamic>.from(userRoleSnapshot.value as List);
      }
      // If 'farmer' is not in the list, and you want to ensure it is for new experts who
      // primarily function as farmers but are also approved experts.
      if (!currentUserRoles.contains('farmer')) {
         currentUserRoles.add('farmer'); // Add 'farmer' to the list
         await _usersRef.child(applicantUid).child('userRole').set(currentUserRoles); // Save the updated list
         print('Added "farmer" role to userRole list for $applicantUid');
      }


      // 4. Delete the application from expert_applications
      await _applicationsRef.child(applicantUid).remove();
      print('Application deleted for $applicantUid');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expert application for ${applicationData['displayName']} APPROVED!')),
      );
    } catch (e) {
      print("Error approving expert application: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve application: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectApplication(String applicantUid) async {
    try {
      await _applicationsRef.child(applicantUid).remove();
      print('Application rejected and deleted for $applicantUid');

      // Optional: If you want to unset isExpert if they had it (e.g., if re-applied and rejected)
      // await _usersRef.child(applicantUid).update({'isExpert': false});
      // print('isExpert flag set to false for $applicantUid (rejected)');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expert application rejected for $applicantUid.')),
      );
    } catch (e) {
      print("Error rejecting expert application: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject application: $e'), backgroundColor: Colors.red),
      );
    }
  }
}