import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'forms/expert_application_form.dart';
import 'package:mjifarm/mainscreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // These lines are for other parts of HomeDashboard not shown, kept for completeness.
    // final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // final WeatherData weatherSummary = getTodayWeatherSummary();
    // final String userName = currentUser?.displayName ?? 'Farmer';

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
                              child: Image.asset('assets/Mjifarms.png'),
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          // This fixes vertical alignment
          children: [
            Text(
              'Welcome to MjiFarms!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final uid = user.uid;
                    DatabaseReference userRef = FirebaseDatabase.instance.ref(
                      "users/$uid",
                    );

                    // Option 1 (Recommended): Use .update() to only modify specified fields.
                    // This will NOT remove 'isExpert' or 'isAdmin' or other existing fields.
                    await userRef.update({
                      "name": user.displayName, // Update display name
                      "email": user.email, // Update email
                      'userRole': ['farmer'], // Set userRole to farmer
                      // IMPORTANT: Do NOT include 'isExpert: false' here unless you intend to specifically remove it.
                      // The current rule for isExpert makes it permanent, so don't try to set it to false here.
                    });

                    // Option 2 (Alternative if you need to fetch and merge, but update() is simpler here):
                    // DataSnapshot existingUserData = await userRef.get();
                    // Map<dynamic, dynamic> dataToSet = {};
                    // if (existingUserData.exists && existingUserData.value is Map) {
                    //   dataToSet = Map.from(existingUserData.value as Map);
                    // }
                    // dataToSet['name'] = user.displayName;
                    // dataToSet['email'] = user.email;
                    // dataToSet['userRole'] = ['farmer'];
                    // // Keep existing 'isExpert' if it was there and not explicitly changed
                    // // If isExpert was true, it would remain true.
                    // await userRef.set(dataToSet);
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
                    MaterialPageRoute(builder: (_) => ExpertApplicationForm()),
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
