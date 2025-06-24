import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mjifarm/auth_gate.dart';

// Import your regular home screen
import 'home.dart'; // Assuming home.dart contains your HomeScreen

// Import your admin dashboard screen
import 'admin/main.dart'; // AdminDashboardScreen is in main.dart after slicing

// Import your new expert dashboard screen
import 'expert/expert_dashboard.dart'; // <-- Correct path for ExpertDashboardScreen

class RoleBasedNavigator extends StatefulWidget {
  const RoleBasedNavigator({super.key});

  @override
  State<RoleBasedNavigator> createState() => _RoleBasedNavigatorState();
}

class _RoleBasedNavigatorState extends State<RoleBasedNavigator> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  bool _isAdmin = false;
  bool _isExpert = false; // This will now correctly reflect the 'isExpert' flag
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is available for potential navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRoles();
    });
  }

  Future<void> _checkUserRoles() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user logged in in RoleBasedNavigator. Redirecting to AuthScreen.");
      // If no user, navigate to your authentication screen
      // Assuming AuthScreen is your initial login/registration page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()), // Replace with your AuthScreen path
        (Route<dynamic> route) => false,
      );
      return; // Exit after scheduling navigation
    }

    try {
      // Fetch the entire user profile to check both 'isAdmin' and 'isExpert'
      DataSnapshot userSnapshot = await _usersRef.child(currentUser.uid).get();
      if (userSnapshot.exists && userSnapshot.value is Map) {
        Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;

        // Check for isAdmin flag directly under user UID
        _isAdmin = userData['isAdmin'] == true;

        // MODIFIED: Check for 'isExpert' flag directly under user UID
        _isExpert = userData['isExpert'] == true;

        print('User ${currentUser.uid} has roles: Admin: $_isAdmin, Expert: $_isExpert');

      } else {
        print('User data not found or invalid for ${currentUser.uid}. Assuming default roles.');
        _isAdmin = false;
        _isExpert = false;
      }
    } catch (e) {
      print("Error fetching user roles for ${currentUser.uid}: $e");
      _isAdmin = false;
      _isExpert = false;
      // Optionally show a snackbar or error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Checking user permissions...'),
            ],
          ),
        ),
      );
    } else {
      // Prioritize admin access, then expert, then regular user
      if (_isAdmin) {
        return const AdminDashboardScreen();
      } else if (_isExpert) { // <-- Use _isExpert for expert routing
        return const HomeScreen(); // <-- Navigate to ExpertDashboardScreen
      } else {
        return const HomeScreen(); // Default for regular farmers
      }
    }
  }
}