import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // For location
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For API key
import 'dart:math'; // For max/min in forecast calculations

// --- Data Models ---
// This is the simple WeatherData class that can be used for summary
class WeatherData {
  final String temperature;
  final String condition;
  final String? iconCode; // Add icon code to fetch dynamically

  WeatherData({required this.temperature, required this.condition, this.iconCode});
}

// --- API Service Functions ---

final String _apiKey ="f02473df10e149ec8cc641bf061fd484";
final String _baseUrl = 'https://api.openweathermap.org/data/2.5';

/// Determines the current position of the device.
/// Throws an error if location services are disabled or permissions are denied.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
}

/// Fetches current weather data from OpenWeatherMap.
/// Returns a Map<String, dynamic> of the raw JSON response.
Future<Map<String, dynamic>> fetchCurrentWeatherData() async {
  if (_apiKey.isEmpty) {
    throw Exception("OpenWeatherMap API key is not configured.");
  }

  try {
    Position position = await _determinePosition();
    final lat = position.latitude;
    final lon = position.longitude;

    final weatherUrl = Uri.parse('$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    final weatherResponse = await http.get(weatherUrl);

    if (weatherResponse.statusCode == 200) {
      return json.decode(weatherResponse.body);
    } else {
      throw Exception('Failed to load current weather: ${weatherResponse.statusCode} ${weatherResponse.body}');
    }
  } catch (e) {
    print('Error in fetchCurrentWeatherData: $e');
    rethrow; // Re-throw to be caught by FutureBuilder
  }
}

/// Fetches 5-day / 3-hour forecast data from OpenWeatherMap.
/// Returns a Map<String, dynamic> of the raw JSON response.
Future<Map<String, dynamic>> fetchForecastData() async {
  if (_apiKey.isEmpty) {
    throw Exception("OpenWeatherMap API key is not configured.");
  }

  try {
    Position position = await _determinePosition();
    final lat = position.latitude;
    final lon = position.longitude;

    final forecastUrl = Uri.parse('$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    final forecastResponse = await http.get(forecastUrl);

    if (forecastResponse.statusCode == 200) {
      return json.decode(forecastResponse.body);
    } else {
      throw Exception('Failed to load forecast: ${forecastResponse.statusCode} ${forecastResponse.body}');
    }
  } catch (e) {
    print('Error in fetchForecastData: $e');
    rethrow; // Re-throw to be caught by FutureBuilder
  }
}

/// Helper to get a simplified weather summary for a specific day.
/// This is what getTodayWeatherSummary will now wrap.
WeatherData getSimplifiedDailyWeatherSummary(Map<String, dynamic> weatherData) {
  final temp = (weatherData['main']?['temp'] as num?)?.round()?.toString() ?? 'N/A';
  final condition = weatherData['weather']?[0]?['description'] ?? 'N/A';
  final iconCode = weatherData['weather']?[0]?['icon'] as String?;
  return WeatherData(temperature: temp, condition: condition, iconCode: iconCode);
}

// The original `getTodayWeatherSummary` should now call the new fetch function.
// This function will be used by HomeDashboard.
Future<WeatherData> getTodayWeatherSummary() async {
  try {
    final weatherJson = await fetchCurrentWeatherData();
    return getSimplifiedDailyWeatherSummary(weatherJson);
  } catch (e) {
    // Return a default or error state WeatherData
    return WeatherData(temperature: 'N/A', condition: 'Error', iconCode: '01d'); // Default sunny icon
  }
}

// Helper to get an icon based on weather condition string
Icon getWeatherIconWidget(String condition) {
  if (condition.toLowerCase().contains('clear') || condition.toLowerCase().contains('sunny')) {
    return Icon(Icons.wb_sunny, color: Colors.orange.shade300);
  } else if (condition.toLowerCase().contains('cloud')) {
    return Icon(Icons.cloud, color: Colors.grey.shade500);
  } else if (condition.toLowerCase().contains('rain')) {
    return Icon(Icons.cloudy_snowing, color: Colors.blue.shade500);
  } else if (condition.toLowerCase().contains('storm') || condition.toLowerCase().contains('thunder')) {
    return Icon(Icons.thunderstorm, color: Colors.indigo.shade500);
  }
  return Icon(Icons.cloud_queue, color: Colors.grey); // Default
}

// Helper to get a weekday string
String getWeekday(int weekday) {
  switch (weekday) {
    case 1: return 'Mon';
    case 2: return 'Tue';
    case 3: return 'Wed';
    case 4: return 'Thu';
    case 5: return 'Fri';
    case 6: return 'Sat';
    case 7: return 'Sun';
    default: return '';
  }
}