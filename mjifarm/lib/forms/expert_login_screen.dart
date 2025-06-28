import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:mjifarm/expert/expert_dashboard.dart';

class ExpertLoginScreen extends StatefulWidget {
  const ExpertLoginScreen({super.key});

  @override
  State<ExpertLoginScreen> createState() => _ExpertLoginScreenState();
}

class _ExpertLoginScreenState extends State<ExpertLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRootRef = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  String? _errorMessage;

  // Helper method to map FirebaseAuthException codes to user-friendly messages
  // This function now accepts a general 'Exception' and handles casting internally
  String _mapFirebaseAuthError(Exception? error) {
    if (error == null) {
      return 'An unknown error occurred.';
    }

    if (error is FirebaseAuthException) {
      print(
        'FirebaseAuthException received by ExpertLoginScreen: Code: ${error.code}, Message: ${error.message}',
      );
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-not-found':
          return 'No expert account found with that email.';
        case 'user-disabled':
          return 'This expert account has been disabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          // This can occur if Firebase tightens email enumeration protection,
          // or if the internal credential given for sign-in is malformed.
          return 'Invalid email or password.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled for this project. Please contact support.';
        default:
          // Fallback for any unhandled FirebaseAuthException codes
          return 'An unexpected authentication error occurred: ${error.message ?? 'Please try again.'}';
      }
    } else {
      // Handle any other non-FirebaseAuthException errors
      print('Non-FirebaseAuthException received by ExpertLoginScreen: $error');
      return 'An unexpected system error occurred: ${error.toString()}';
    }
  }

  Future<void> _signInAsExpert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Fetch the user's 'isExpert' flag directly
        DataSnapshot isExpertSnapshot =
            await _databaseRootRef
                .child('users')
                .child(user.uid)
                .child('isExpert')
                .get();

        bool isExpert = false;
        if (isExpertSnapshot.exists && isExpertSnapshot.value == true) {
          isExpert = true;
        }

        if (isExpert) {
          // User is an expert, navigate to expert dashboard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful! Welcome, Expert.'),
                backgroundColor: Colors.green, // Success color
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ExpertDashboardScreen(),
              ),
            );
          }
        } else {
          // User is authenticated but NOT an expert, sign them out and show error
          await _auth.signOut(); // Sign out the non-expert user
          setState(() {
            _errorMessage =
                'Access Denied: Your account does not have expert privileges.';
          });
        }
      } else {
        // This case should ideally not be reached if signInWithEmailAndPassword succeeded.
        // It's a fallback for an unexpected state.
        setState(() {
          _errorMessage =
              'Login successful, but user data could not be retrieved. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      // Use the helper method to get the user-friendly message
      setState(() {
        _errorMessage = _mapFirebaseAuthError(e);
      });
    } catch (e) {
      // Catch any other unexpected exceptions (non-FirebaseAuthException)
      setState(() {
        _errorMessage = _mapFirebaseAuthError(e as Exception?);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50], // Added for consistent background
      appBar: AppBar(
        title: const Text('Expert Login'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        foregroundColor:
            Colors.white, // Added for consistent app bar text color
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100, // Light red background
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 28,
                          ), // Darker red icon
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ------------------------------------
                Image.asset(
                  height: 200,
                  "assets/Mjifarms.png",
                  // Added errorBuilder for the image asset itself
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      'Error loading Mjifarms.png in ExpertLoginScreen: $error',
                    );
                    return const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  'Sign In as an Expert',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your expert email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _signInAsExpert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Login as Expert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
