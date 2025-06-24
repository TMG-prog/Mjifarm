import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
// For Uint8List
import 'package:flutter/material.dart'; // Needed for SnackBar
import 'package:geolocator/geolocator.dart'; // REQUIRED: Import geolocator for location

// This function now returns a Base64 string of the image bytes


// Function to get current user location (Requires geolocator permissions setup)
Future<Position?> getCurrentUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services are disabled.');
    // Consider showing a dialog to the user
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permissions are denied');
      // Consider showing a dialog explaining why permission is needed
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permissions are permanently denied, we cannot request permissions.');
    // Consider showing a dialog directing user to app settings
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  } catch (e) {
    print('Error getting location: $e');
    return null;
  }
}

// Updated function to call Vercel, now accepting optional latitude and longitude
Future<Map<String, dynamic>?> callPlantDiagnosisVercel( // Changed return type to Map<String, dynamic>?
  String base64Image,
  String cropLogId,
  String plantId,
  BuildContext context,
  {double? latitude, double? longitude} // Added optional named parameters
) async {
  try {
    // Get Firebase User ID Token
    String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (idToken == null) {
      print("User not authenticated. Cannot call Vercel function.");
      ScaffoldMessenger.of(context).showSnackBar( // Show error to user
        const SnackBar(content: Text('Authentication required. Please log in.')),
      );
      return null; // Return null if not authenticated
    }

    // Prepare the request body map
    Map<String, dynamic> requestBody = {
      'base64Image': base64Image, // Sending Base64 string
      'cropLogId': cropLogId,
      'plantId': plantId,
    };

    // Conditionally add latitude and longitude if they are provided
    if (latitude != null) {
      requestBody['latitude'] = latitude;
    }
    if (longitude != null) {
      requestBody['longitude'] = longitude;
    }

    final response = await http.post(
      Uri.parse('https://mjifarms-backend.vercel.app/diagnose'), // Correctly pointing to /diagnose
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $idToken', // Send ID Token for verification
      },
      body: jsonEncode(requestBody), // Encode the full map with optional location
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print("Vercel Function Result: $responseData");
      if (responseData['status'] == 'success') {
        print("Diagnosis successful from Vercel: ${responseData['diagnosisId']}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant diagnosed successfully!')),
        );
        return responseData['diagnosisDetails']; // Return the diagnosis details
      } else {
        print("Diagnosis failed from Vercel: ${responseData['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnosis failed: ${responseData['message']}')),
        );
        return null; // Return null on failure
      }
    } else if (response.statusCode == 405) {
      print("Vercel Function Error: 405 Method Not Allowed.");
      print("Response body: ${response.body}"); // Log the response body for more info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server Error: Method Not Allowed. Please check backend configuration.')),
      );
      return null;
    } else if (response.statusCode == 400) { // Example for Bad Request
        print("Vercel Function Error: 400 Bad Request. ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid request: ${response.body}')),
        );
        return null;
    }
    else {
      print("Vercel Function Error: ${response.statusCode}");
      print("Response body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected server error occurred (${response.statusCode}).')),
      );
      return null;
    }
  } catch (e) {
    print('Error calling Vercel function: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: Failed to connect to server. ($e)')),
    );
    return null; // Return null on network error
  }
}
