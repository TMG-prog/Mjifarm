import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

// Import your new RoleBasedNavigator
import 'role_based_navigator.dart'; // Adjust 'your_app_name'

// No direct import for 'home.dart' or 'main.dart' needed here anymore,
// as RoleBasedNavigator handles the decision.

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // If no user is signed in, show the sign-in screen
          print('User is not signed in. Showing SignInScreen.');
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: "535637157454-cn72t4ssrmr4hl7j90o0psb4u5k92159.apps.googleusercontent.com")
            ],
            headerBuilder: (context, constraints, shrinkOffSet) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/Mjifarms.png'),
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
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/Mjifarms.png'), // Ensure this path is correct if different from main bundle
                ),
              );
            },
          );
        } else {
          // User is signed in. Now, use RoleBasedNavigator to determine
          // whether to show the regular home screen or the admin dashboard.
          print('User is signed in. Navigating to RoleBasedNavigator.');
          return const RoleBasedNavigator(); // <--- THIS IS THE CHANGE
        }
      },
    );
  }
}
