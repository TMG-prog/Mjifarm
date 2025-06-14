import 'package:flutter/material.dart';
import 'package:mjifarm/homePage.dart';
import 'package:mjifarm/newplant.dart';
import 'package:mjifarm/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MjiFarms',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE8EDDE),
        primaryColor: const Color(0xFF375E32),
        hintColor: const Color(0xFF7D9D76),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2D3C29)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Color(0xFF7D9D76)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFC6D6B8),
          iconTheme: IconThemeData(color: Color(0xFF375E32)),
          titleTextStyle: TextStyle(
            color: Color(0xFF375E32),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF375E32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
