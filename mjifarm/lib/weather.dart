// lib/weather.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

// --- Data Models ---
// This class holds simplified weather information for display.
class WeatherData {
  final String temperature;
  final String condition;
  final String? iconCode; // OpenWeatherMap icon code (e.g., "01d", "04n")

  WeatherData({required this.temperature, required this.condition, this.iconCode});
}

// --- API Service Configuration ---

// The base URL for your Vercel Serverless Function.
// Replace 'YOUR_VERCEL_API_PROJECT_NAME' with the actual
// name of the Vercel project deployed for the weather API.
// The '/api' path is based on your Vercel project structure (api/index.js).
const String _vercelApiBaseUrl = 'https://mjifarms-weather.vercel.app/api';

// --- Location Service Function ---

/// Determines the current position (latitude and longitude) of the device.
/// This function handles permissions and ensures location services are enabled.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled; don't continue.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Permissions are granted, continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

// --- API Fetching Functions (via Vercel Serverless Function) ---

/// Fetches current weather data for the device's current location
/// by calling the Vercel Serverless Function.
///
/// Returns a Map<String, dynamic> representing the JSON response from OpenWeatherMap.
Future<Map<String, dynamic>> fetchCurrentWeatherData() async {
  try {
    Position position = await _determinePosition(); // Get current location
    final lat = position.latitude;
    final lon = position.longitude;

    // Construct the URL to call the Vercel Serverless Function
    // Pass latitude, longitude, and 'weather' type as query parameters.
    final vercelUrl = Uri.parse('$_vercelApiBaseUrl?lat=$lat&lon=$lon&type=weather');
    // print('Calling Vercel API for current weather: $vercelUrl'); // Debugging print

    final response = await http.get(vercelUrl);

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return json.decode(response.body);
    } else {
      // If the server returns an error, throw an exception.
      final errorBody = json.decode(response.body);
      // print('Error fetching current weather from Vercel function: ${response.statusCode} - ${errorBody['error'] ?? response.body}'); // Debugging print
      throw Exception('Failed to load current weather from Vercel function: ${response.statusCode} ${errorBody['error'] ?? response.body}');
    }
  } catch (e) {
    // Catch any exceptions during the process (e.g., network error, permission error).
    // print('Exception in fetchCurrentWeatherData (via Vercel): $e'); // Debugging print
    rethrow; // Re-throw the exception so calling widgets can handle it.
  }
}

/// Fetches 5-day / 3-hour forecast data for the device's current location
/// by calling the Vercel Serverless Function.
///
/// Returns a Map<String, dynamic> representing the JSON response from OpenWeatherMap.
Future<Map<String, dynamic>> fetchForecastData() async {
  try {
    Position position = await _determinePosition(); // Get current location
    final lat = position.latitude;
    final lon = position.longitude;

    // Construct the URL to call the Vercel Serverless Function
    // Pass latitude, longitude, and 'forecast' type as query parameters.
    final vercelUrl = Uri.parse('$_vercelApiBaseUrl?lat=$lat&lon=$lon&type=forecast');
    // print('Calling Vercel API for forecast: $vercelUrl'); // Debugging print

    final response = await http.get(vercelUrl);

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return json.decode(response.body);
    } else {
      // If the server returns an error, throw an exception.
      final errorBody = json.decode(response.body);
      // print('Error fetching forecast from Vercel function: ${response.statusCode} - ${errorBody['error'] ?? response.body}'); // Debugging print
      throw Exception('Failed to load forecast from Vercel function: ${response.statusCode} ${errorBody['error'] ?? response.body}');
    }
  } catch (e) {
    // Catch any exceptions during the process.
    // print('Exception in fetchForecastData (via Vercel): $e'); // Debugging print
    rethrow;
  }
}

// --- Weather Data Processing and UI Helpers ---

/// Extracts and simplifies current weather data from the OpenWeatherMap JSON response.
///
/// [weatherData]: The JSON response map for current weather.
/// Returns a [WeatherData] object.
WeatherData getSimplifiedDailyWeatherSummary(Map<String, dynamic> weatherData) {
  final temp = (weatherData['main']?['temp'] as num?)?.round()?.toString() ?? 'N/A';
  final condition = weatherData['weather']?[0]?['description'] ?? 'N/A';
  final iconCode = weatherData['weather']?[0]?['icon'] as String?;
  return WeatherData(temperature: temp, condition: condition, iconCode: iconCode);
}

/// A convenience function to get today's weather summary directly.
/// Handles potential errors and returns a default [WeatherData] in case of failure.
Future<WeatherData> getTodayWeatherSummary() async {
  try {
    final weatherJson = await fetchCurrentWeatherData();
    return getSimplifiedDailyWeatherSummary(weatherJson);
  } catch (e) {
    // print('Failed to get today\'s weather summary: $e'); // Debugging print
    // Return a default error state
    return WeatherData(temperature: 'N/A', condition: 'Error', iconCode: '01d');
  }
}

/// Provides a suitable Material Design icon based on weather condition text.
///
/// [condition]: A string describing the weather (e.g., "clear sky", "cloudy").
/// Returns an [Icon] widget.
Icon getWeatherIconWidget(String condition) {
  if (condition.toLowerCase().contains('clear') || condition.toLowerCase().contains('sunny')) {
    return Icon(Icons.wb_sunny, color: Colors.orange.shade300);
  } else if (condition.toLowerCase().contains('cloud')) {
    return Icon(Icons.cloud, color: Colors.grey.shade500);
  } else if (condition.toLowerCase().contains('rain') || condition.toLowerCase().contains('drizzle')) {
    return Icon(Icons.cloudy_snowing, color: Colors.blue.shade500);
  } else if (condition.toLowerCase().contains('storm') || condition.toLowerCase().contains('thunder')) {
    return Icon(Icons.thunderstorm, color: Colors.indigo.shade500);
  } else if (condition.toLowerCase().contains('snow')) {
    return Icon(Icons.ac_unit, color: Colors.blue.shade200);
  } else if (condition.toLowerCase().contains('mist') || condition.toLowerCase().contains('fog') || condition.toLowerCase().contains('haze')) {
    return Icon(Icons.dehaze, color: Colors.grey.shade400);
  }
  return Icon(Icons.cloud_queue, color: Colors.grey); // Default icon
}

/// Converts a weekday integer (1=Mon, 7=Sun) to a short string.
String getWeekday(int weekday) {
  switch (weekday) {
    case 1: return 'Mon';
    case 2: return 'Tue';
    case 3: return 'Wed';
    case 4: return 'Thu';
    case 5: return 'Fri';
    case 6: return 'Sat';
    case 7: return 'Sun';
    default: return ''; // Should not happen for valid weekday ints
  }
}
