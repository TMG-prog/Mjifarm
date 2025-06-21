import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mjifarm/fprofile.dart';
import 'package:mjifarm/mainscreen.dart';
import 'Login.dart';
import 'home_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder:
                      (context) => ProfileScreen(
                        appBar: AppBar(title: const Text('User Profile')),
                        actions: [
                          SignedOutAction((context) {
                            Navigator.of(context).pop();
                          }),
                        ],
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.asset('Mjifarms.jpg'),
                            ),
                          ),
                        ],
                      ),
                ),
              );
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // This fixes vertical alignment
          children: [
            Text(
              'Welcome to MjiFarms!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final name = user.displayName;
                    final uid = user.uid;
                    final email = user.email;
                    DatabaseReference ref = FirebaseDatabase.instance.ref(
                      "users/$uid",
                    );
                    await ref.set({
                      "name": name,
                      "email": email,
                      'userRole': ['farmer'],
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MainScreen()),
                  );
                },
                label: const Text("Join As a Farmer"),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                label: const Text("Join As an Expert"),
              ),
            ),
            const SizedBox(height: 40),
            const SignOutButton(),
          ],
        ),
      ),
    );
  }
}
