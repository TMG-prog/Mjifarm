import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'role_based_navigator.dart'; 
import 'package:mjifarm/forms/expert_login_screen.dart'; 


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _errorMessage; 

  
  String _mapFirebaseAuthError(Exception? error) {
   
    if (error == null) {
      return 'An unknown error occurred.';
    }

    if (error is FirebaseAuthException) {
      print('FirebaseAuthException received by AuthGate: Code: ${error.code}, Message: ${error.message}');
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'weak-password':
          return 'The password is too weak. Please choose a stronger one (min 6 characters).';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled. Please contact support.';
        case 'invalid-credential':
          return 'Invalid email or password.'; // Custom message for this error
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different login method. Please sign in with your other method.';
        case 'popup-closed-by-user': // Specific for web, if popup is closed manually
          return 'Sign-In window was closed.';
        default:
          // Fallback for any unhandled FirebaseAuthException codes
          return 'An unexpected authentication error occurred: ${error.message ?? 'Please try again.'}';
      }
    } else {
      // Handle any other non-FirebaseAuthException errors
      print('Non-FirebaseAuthException received by AuthGate: $error');
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print('User is not signed in. Showing SignInScreen.');
          return Scaffold(
            body: Column(
              children: [
                // Custom Error Message Display at the top
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.red.shade100, // Light red background for the error
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                Expanded( 
                  child: SignInScreen(
                    providers: [
                      EmailAuthProvider(),
                      GoogleProvider(clientId: "535637157454-cn72t4ssrmr4hl7j90o0psb4u5k92159.apps.googleusercontent.com")
                    ],
                    headerBuilder: (context, constraints, shrinkOffSet) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            'assets/Mjifarms.png',
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading Mjifarms.png in header: $error');
                              return const Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    subtitleBuilder: (context, action) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: action == AuthAction.signIn
                            ? const Text('Welcome to MjiFarms, please sign in')
                            : const Text('Welcome to MjiFarms, please sign up!'),
                      );
                    },
                    footerBuilder: (context, action) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'By signing in, you agree to our terms and conditions',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/expert-login');
                              },
                              icon: const Icon(Icons.verified_user),
                              label: const Text('Are you an Expert? Sign in here'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green.shade700,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    sideBuilder: (context, shrinkOffset) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            'assets/Mjifarms.png',
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading Mjifarms.png in side: $error');
                              return const Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.redAccent,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    actions: [
                      // This action is triggered when any authentication attempt fails
                      // The 'state' object for AuthFailed has an 'exception' field of type Exception.
                      AuthStateChangeAction<AuthFailed>((context, state) {
                        setState(() {
                          _errorMessage = _mapFirebaseAuthError(state.exception);
                        });
                      }),
                      // This action is triggered on successful sign-in
                      AuthStateChangeAction<SignedIn>((context, state) {
                        setState(() {
                          _errorMessage = null; // Clear error message on successful sign-in
                        });
                      }),
                     
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          print('User is signed in. Navigating to RoleBasedNavigator.');
          return const RoleBasedNavigator();
        }
      },
    );
  }
}