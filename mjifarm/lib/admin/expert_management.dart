import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference
import 'package:firebase_auth/firebase_auth.dart'; // Needed for FirebaseAuth (e.g., for isAdmin check in rules)

class ExpertManagementContent extends StatefulWidget {
  const ExpertManagementContent({super.key});

  @override
  State<ExpertManagementContent> createState() => _ExpertManagementContentState();
}

class _ExpertManagementContentState extends State<ExpertManagementContent> {
  late DatabaseReference _expertsRef;
  late DatabaseReference _usersRef; // Reference to the 'users' node for updating isExpert
  List<Map<String, dynamic>> _experts = [];
  bool _isLoading = true;

  // Removed: TextEditingControllers for name, expertiseArea, contactHandle, email, password
  // Removed: _formKey

  @override
  void initState() {
    super.initState();
    _expertsRef = FirebaseDatabase.instance.ref('expert_profiles');
    _usersRef = FirebaseDatabase.instance.ref('users'); // Initialize users ref
    _listenToExperts();
  }

  @override
  void dispose() {
    // Removed: Disposal of all TextEditingControllers
    super.dispose();
  }

  void _listenToExperts() {
    _expertsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedExperts = [];
        data.forEach((key, value) {
          if (value is Map) {
            // 'key' here is the Firebase Auth UID
            fetchedExperts.add({
              'id': key, // This 'id' is the Firebase Auth UID
              'userID': value['userID'] ?? key, 
              'name': value['name'] ?? '',
              'expertiseArea': value['expertiseArea'] ?? '',
              'contactHandle': value['contactHandle'] ?? '',
              'isVerified': value['isVerified'] ?? false, // Expert profile verification status
              'email': value['email'] ?? '',
            });
          }
        });
        setState(() {
          _experts = fetchedExperts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _experts = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error listening to experts: $error");
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Error fetching experts: $error", Colors.red);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), backgroundColor: color),
    );
  }

  void _handleVerify(String expertAuthUid, bool currentVerifiedStatus) { 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Action'),
          content: Text('Are you sure you want to ${currentVerifiedStatus ? "unverify" : "verify"} expert?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update 'isVerified' in expert_profiles
                  await _expertsRef.child(expertAuthUid).update({'isVerified': !currentVerifiedStatus}); 

                  // Update 'isExpert' flag in 'users' node based on verification status
                  await _usersRef.child(expertAuthUid).update({'isExpert': !currentVerifiedStatus});

                  _showSnackBar('Expert verification status toggled.', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to update verification: $e', Colors.red);
                } finally {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(String expertAuthUid) { 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this expert? This will remove their profile and user role.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Delete expert profile from 'expert_profiles' node using Auth UID as key
                  await _expertsRef.child(expertAuthUid).remove();

                  // 2. Remove 'isExpert' flag from 'users' node
                  // Using update with null value removes the field
                  await _usersRef.child(expertAuthUid).update({'isExpert': null}); 

                  // Optional: If you also want to remove 'expert' from the userRole list (if it was ever added there)
                  // You'd need to fetch, modify list, and then update.
                  // For now, assuming isExpert is the primary flag.

                  // 3. (Consideration) Delete corresponding Firebase Auth user:
                  // This operation requires Firebase Admin SDK or specific client-side re-authentication.
                  // For a robust solution, consider a Firebase Cloud Function for user deletion.
                  // Deleting only the RTDB nodes here.

                  _showSnackBar('Expert profile and Realtime DB user data updated (isExpert removed).', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to delete expert: $e', Colors.red);
                  print("Error deleting expert: $e");
                } finally {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Removed: _handleAddExpert method entirely.

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
            'Expert Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 24),
          // Removed: The entire Card containing the "Add New Expert" form.
          // This includes the Form, TextFormFields, and the Add Expert button.
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 16.0,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Expertise', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Contact Handle', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Verified', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _experts.map((expert) => DataRow(cells: [
                    DataCell(Text(expert['name'] ?? 'N/A')),
                    DataCell(Text(expert['expertiseArea'] ?? 'N/A')),
                    DataCell(Text(expert['contactHandle'] ?? 'N/A')),
                    DataCell(
                      Chip(
                        label: Text(expert['isVerified'] == true ? 'Yes' : 'No', style: TextStyle(color: expert['isVerified'] == true ? Colors.green.shade800 : Colors.red.shade800)),
                        backgroundColor: expert['isVerified'] == true ? Colors.green.shade100 : Colors.red.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(expert['isVerified'] == true ? Icons.check_circle : Icons.circle_outlined, color: expert['isVerified'] == true ? Colors.green : Colors.grey),
                            tooltip: expert['isVerified'] == true ? 'Unverify Expert' : 'Verify Expert',
                            onPressed: () => _handleVerify(expert['id'], expert['isVerified'] == true), 
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Expert',
                            onPressed: () => _handleDelete(expert['id']), 
                          ),
                        ],
                      ),
                    ),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}