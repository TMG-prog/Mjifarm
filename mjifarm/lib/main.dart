// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mjifarm/newplant.dart';
import 'package:mjifarm/reminder.dart';
import 'splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mjifarm/plants.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth_gate.dart';
import 'package:mjifarm/forms/expert_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

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
        // You can still set InputDecorationTheme here if you want consistent styling for TextFormFields
        inputDecorationTheme: InputDecorationTheme(
          errorStyle: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
          // Further customize border, hint, label colors if needed
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.green, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
      ),
      home: const Splash(), 
      localizationsDelegates: const [ 
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      debugShowCheckedModeBanner: false,
      routes: {
        '/newplant': (context) => NewPlantPage(),
        '/reminder': (context) => ReminderPage(),
        'myplants': (context) => MyPlantsPage(),
        '/expert-login': (context) => const ExpertLoginScreen(),
      },
    );
  }
}