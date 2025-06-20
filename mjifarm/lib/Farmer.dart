import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'diagnosis.dart'; // Import your Plant Identification page

class FarmerPage extends StatelessWidget {
  const FarmerPage({super.key});

  Future<String?> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$uid/name");
      DatabaseEvent event = await ref.once();
      return event.snapshot.value?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("Welcome")),
      body: Center(
        child: FutureBuilder<String?>(
          future: getUserName(),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            String displayName = '';
            if (snapshot.connectionState == ConnectionState.waiting) {
              displayName = 'Loading..';
            } else if (snapshot.hasError) {
              displayName = 'Error: ${snapshot.error}';
            } else if (snapshot.data != null) {
              displayName = snapshot.data!;
            } else {
              displayName = 'Farmer';
            }
            return Scaffold(
              body: Center(
                child: Column(
                  // <-- Use Column as the child of Center
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Center contents vertically within the Column
                  children: <Widget>[
                    // <-- Now Column has the children
                    Text(
                      'Welcome to the Farmer Page',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the Crop Log Page
                        Navigator.pushNamed(context, '/cropLog');
                      },
                      child: Text('Go to Crop Log'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the Plant Identification Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyDiagnosisScreen(),
                          ),
                        );
                      },
                      child: Text('Go to Plant Identification'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
