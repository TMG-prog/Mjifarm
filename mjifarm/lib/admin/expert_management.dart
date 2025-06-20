import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference and ServerValue
// import 'package:uuid/uuid.dart'; // No longer needed as we use Firebase Auth UID as primary key
import 'package:firebase_auth/firebase_auth.dart'; // Needed for FirebaseAuth

class ExpertManagementContent extends StatefulWidget {
  const ExpertManagementContent({super.key});

  @override
  State<ExpertManagementContent> createState() => _ExpertManagementContentState();
}

class _ExpertManagementContentState extends State<ExpertManagementContent> {
  late DatabaseReference _expertsRef;
  late DatabaseReference _usersRef; 
  List<Map<String, dynamic>> _experts = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expertiseAreaController = TextEditingController();
  final TextEditingController _contactHandleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Password Controller

  @override
  void initState() {
    super.initState();
    _expertsRef = FirebaseDatabase.instance.ref('expert_profiles');
    _usersRef = FirebaseDatabase.instance.ref('users'); 
    _listenToExperts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expertiseAreaController.dispose();
    _contactHandleController.dispose();
    _emailController.dispose();
    _passwordController.dispose(); 
    super.dispose();
  }

  void _listenToExperts() {
    _expertsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedExperts = [];
        data.forEach((key, value) {
          if (value is Map) {
            // 'key' here will now be the Firebase Auth UID directly
            fetchedExperts.add({
              'id': key, // This 'id' is now the Firebase Auth UID
              'userID': value['userID'] ?? key, // Fallback to key if userID is not explicitly stored/needed
              'name': value['name'] ?? '',
              'expertiseArea': value['expertiseArea'] ?? '',
              'contactHandle': value['contactHandle'] ?? '',
              'isVerified': value['isVerified'] ?? false,
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
                  // Use expertAuthUid as the key for updating
                  await _expertsRef.child(expertAuthUid).update({'isVerified': !currentVerifiedStatus}); 
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
          content: const Text('Are you sure you want to delete this expert? This will remove their profile and associated user data.'),
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

                  // 2. Delete corresponding user entry from 'users' node using the AUTH UID
                  // Remember: Deleting a Firebase Auth user account itself from the client
                  // is generally not recommended or requires re-authentication.
                  // For a robust solution, consider using a Firebase Cloud Function.
                  await _usersRef.child(expertAuthUid).remove(); 
                  
                  _showSnackBar('Expert profile and Realtime DB user data deleted.', Colors.green);
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

  void _handleAddExpert() async {
    if (_formKey.currentState!.validate()) {
      try {
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String password = _passwordController.text;
        final String expertiseArea = _expertiseAreaController.text.trim();
        final String contactHandle = _contactHandleController.text.trim();

        if (password.isEmpty || password.length < 6) {
          _showSnackBar('Password must be at least 6 characters long.', Colors.red);
          return;
        }

        // 1. Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        String newExpertAuthUid = userCredential.user!.uid; // Get the UID from Firebase Auth

        // 2. Save expert profile to Realtime Database's 'expert_profiles' node
        //    CRITICAL CHANGE: Use the Firebase Auth UID as the key for the expert_profiles entry
        await _expertsRef.child(newExpertAuthUid).set({ 
          'userID': newExpertAuthUid, // Keep for clarity, or remove if key is always UID
          'name': name,
          'email': email,
          'expertiseArea': expertiseArea,
          'contactHandle': contactHandle,
          'isVerified': false, 
        });

        // 3. Save user data (including role) to Realtime Database's 'users' node
        await _usersRef.child(newExpertAuthUid).set({
          'email': email,
          'name': name,
          'userRole': ['expert'], 
          'status': 'active', 
          'registrationDate': ServerValue.timestamp, 
        });

        _nameController.clear();
        _expertiseAreaController.clear();
        _contactHandleController.clear();
        _emailController.clear();
        _passwordController.clear();
        _showSnackBar('Expert $name added successfully! They can now log in.', Colors.green);

      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
          message = 'Firebase Auth Error: ${e.message}';
        }
        _showSnackBar(message, Colors.red);
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      } catch (e) {
        _showSnackBar('Failed to add expert: $e', Colors.red);
        print("General Error adding expert: $e");
      }
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
            'Expert Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Expert',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Expert Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter expert name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _expertiseAreaController,
                          decoration: InputDecoration(
                            labelText: 'Expertise Area (e.g., Pest Control)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter expertise area';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactHandleController,
                          decoration: InputDecoration(
                            labelText: 'Contact Handle (e.g., @agri_expert)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField( 
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Initial Password (min 6 characters)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _handleAddExpert,
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Add Expert'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
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
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
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
                            // Pass the Firebase Auth UID (which is now 'id' for this expert profile)
                            onPressed: () => _handleVerify(expert['id'], expert['isVerified'] == true), 
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Expert',
                            // Pass the Firebase Auth UID (which is now 'id' for this expert profile)
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