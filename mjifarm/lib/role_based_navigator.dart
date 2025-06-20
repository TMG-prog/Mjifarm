import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Import your regular home screen
import 'home.dart'; // Assuming home.dart contains your HomeScreen

// Import your admin dashboard screen
import 'admin/main.dart'; // AdminDashboardScreen is in main.dart after slicing

// Import your new expert dashboard screen
import 'expert/expert_dashboard.dart'; // <-- NEW IMPORT

class RoleBasedNavigator extends StatefulWidget {
  const RoleBasedNavigator({super.key});

  @override
  State<RoleBasedNavigator> createState() => _RoleBasedNavigatorState();
}

class _RoleBasedNavigatorState extends State<RoleBasedNavigator> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  bool _isAdmin = false;
  bool _isExpert = false; // <-- NEW state variable for expert role
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRoles(); // Renamed function for clarity
  }

  Future<void> _checkUserRoles() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user logged in in RoleBasedNavigator.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DataSnapshot userSnapshot = await _usersRef.child(currentUser.uid).get(); // Get entire user profile
      if (userSnapshot.exists && userSnapshot.value is Map) {
        Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;

        // Check for isAdmin flag
        if (userData['isAdmin'] == true) {
          _isAdmin = true;
        }

        // Check for expert role in userRole array
        if (userData['userRole'] is List) {
          List<dynamic> roles = userData['userRole'];
          if (roles.contains('expert')) {
            _isExpert = true;
          }
        }
        print('User ${currentUser.uid} has roles: Admin: $_isAdmin, Expert: $_isExpert');

      } else {
        print('User data not found or invalid for ${currentUser.uid}');
      }
    } catch (e) {
      print("Error fetching user roles for ${currentUser.uid}: $e");
      // Default to non-admin/non-expert on error
      _isAdmin = false;
      _isExpert = false;
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
      } else if (_isExpert) { // <-- NEW conditional routing
        return const ExpertDashboardScreen();
      } else {
        return const HomeScreen();
      }
    }
  }
}
