import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

// Import the existing screen files
import 'dashboard_content.dart';
import 'user_management.dart';
import 'expert_management.dart'; // This is for approved experts
import 'crop_info_management_content.dart';
import 'diagnosis_review.dart';

import 'expert_application_screen.dart';

// Global Firebase configuration variables (provided by the environment)
final String? __app_id = null; // Placeholder for Canvas environment
final String? __firebase_config = null; // Placeholder for Canvas environment
final String? __initial_auth_token = null; // Placeholder for Canvas environment

// Initialize Firebase (called once at app start)
Future<void> _initializeFirebase() async {
  try {
    Map<String, dynamic> firebaseConfig = {};
    if (__firebase_config != null) {
      firebaseConfig = Map<String, dynamic>.from(json.decode(__firebase_config!));
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: firebaseConfig['apiKey'] ?? '',
        appId: firebaseConfig['appId'] ?? '',
        messagingSenderId: firebaseConfig['messagingSenderId'] ?? '',
        projectId: firebaseConfig['projectId'] ?? '',
        databaseURL: firebaseConfig['databaseURL'] ?? '',
        storageBucket: firebaseConfig['storageBucket'] ?? '',
      ),
    );

    final FirebaseAuth auth = FirebaseAuth.instance;
    if (__initial_auth_token != null) {
      await auth.signInWithCustomToken(__initial_auth_token!);
      print('Signed in with custom token!');
    } else {
      await auth.signInAnonymously();
      print('Signed in anonymously!');
    }

  } catch (e) {
    print('Error initializing Firebase or signing in: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mjifarms Admin',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A24),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: const AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoadingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        print('User is currently signed out!');
        setState(() {
          _currentUser = null;
          _isAdmin = false;
          _isLoadingAuth = false;
        });
      } else {
        print('User is signed in: ${user.uid}');
        setState(() {
          _currentUser = user;
        });
        try {
          DataSnapshot userSnapshot = await _databaseRef.child('users/${user.uid}/isAdmin').get();
          if (userSnapshot.exists && userSnapshot.value == true) {
            setState(() {
              _isAdmin = true;
            });
            print('User is an admin.');
          } else {
            setState(() {
              _isAdmin = false;
            });
            print('User is not an admin.');
          }
        } catch (e) {
          print("Error checking admin status: $e");
          setState(() {
            _isAdmin = false;
          });
        } finally {
          setState(() {
            _isLoadingAuth = false;
          });
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Checking Admin Status...'),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 20),
                Text(
                  'You do not have administrative privileges to access this dashboard.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red.shade700),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // List of screens for navigation
    final List<Widget> widgetOptions = <Widget>[
      DashboardContent(),
      UserManagementContent(),
      ExpertManagementContent(),
      CropInfoManagementContent(),
      DiagnosisReviewContent(),
      AdminExpertApplicationsScreen(), // NEW: Add the Expert Applications screen here
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MjiFarms Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 600)
            NavigationRail(
              backgroundColor: const Color(0xFF1E3A24),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: Colors.greenAccent),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Colors.greenAccent),
              minWidth: 100,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.military_tech_outlined),
                  selectedIcon: Icon(Icons.military_tech),
                  label: Text('Experts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_florist_outlined),
                  selectedIcon: Icon(Icons.local_florist),
                  label: Text('Crop Info'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('Diagnoses'),
                ),
                // NEW: Add destination for Expert Applications
                NavigationRailDestination(
                  icon: Icon(Icons.how_to_reg_outlined), // Or Icons.assignment_ind_outlined, Icons.gavel_outlined
                  selectedIcon: Icon(Icons.how_to_reg),
                  label: Text('Applications'), // Label for the new section
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Icon(Icons.spa, size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              labelType: NavigationRailLabelType.all,
            ),
          Expanded(
            child: widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.military_tech),
                  label: 'Experts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_florist),
                  label: 'Crop Info',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.monitor_heart),
                  label: 'Diagnoses',
                ),
                // NEW: Add item for Expert Applications
                BottomNavigationBarItem(
                  icon: Icon(Icons.how_to_reg),
                  label: 'Applications',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 8,
            )
          : null,
    );
  }
}