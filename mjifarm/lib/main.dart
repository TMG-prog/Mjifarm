import 'package:flutter/material.dart';
import 'package:mjifarm/home.dart';
import 'package:mjifarm/home_dashboard.dart';
import 'package:mjifarm/reminder.dart';
import 'splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MjiFarms',
      theme: ThemeData(
        fontFamily: 'NotoSerif',
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Splash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
