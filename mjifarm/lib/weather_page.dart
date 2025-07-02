// lib/pages/weather_home_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For sending FCM token to backend
import 'dart:convert'; // For jsonEncode
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:mjifarm/weather.dart' as weather_api; // ALIAS for your weather functions
import 'package:flutter/foundation.dart' show defaultTargetPlatform; // For platform info

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Map<String, dynamic>? _currentWeatherData;
  String? _errorMessage;
  bool _isLoading = true;
  String? _fcmToken;
  Position? _currentPosition; // To store the device's current location

  // --- IMPORTANT: Replace with your actual backend API endpoint ---
  // This is where your server will receive and store the FCM tokens.
  static const String _backendApiEndpoint =
      'https://mjifarms-weather.vercel.app/api'; // Changed to just /api as /api/index.js is the default handler for POST
  // Example for a local test server: 'http://10.0.2.2:3000/registerFcmToken' (for Android emulator)
  // Example for a deployed server: 'https://api.yourdomain.com/registerFcmToken'

  @override
  void initState() {
    super.initState();
    // Fetch initial weather data and then configure FCM
    // We call both, but ensure FCM token sending with location happens after _currentPosition is set.
    _fetchWeatherData();
    _configureFirebaseMessaging(); // Setup FCM listeners and token sending
  }

  // --- Location and Weather Fetching Logic ---
  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get Location Permissions and Current Position
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in your device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant permission for the app to function.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in your app settings.');
      }

      // If permissions are granted, get the current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // High accuracy for weather
        timeLimit: const Duration(seconds: 15), // Timeout for location
      );
      print('Fetched device location: Lat ${_currentPosition!.latitude}, Lon ${_currentPosition!.longitude}');


      // 2. Fetch Weather Data using the obtained location
      final data = await weather_api.fetchCurrentWeatherData(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _currentWeatherData = data;
        _isLoading = false;
      });

      // --- IMPORTANT: Send FCM token with location AFTER _currentPosition is confirmed ---
      if (_fcmToken != null) {
        print('Location now available. Resending FCM token with updated location.');
        await _sendFcmTokenToBackend(_fcmToken!, _currentPosition);
      } else {
        print('FCM token not yet available. Location will be sent with token once it\'s obtained.');
      }
      // --- END IMPORTANT CHANGE ---

    } catch (e) {
      print('Error fetching weather or location: $e');
      setState(() {
        if (e.toString().contains('Location services are disabled')) {
          _errorMessage = 'Location services are disabled. Please enable them.';
        } else if (e.toString().contains('Location permissions are denied')) {
          _errorMessage =
              'Location permissions denied. Please grant permission in app settings.';
        } else if (e.toString().contains('permanently denied')) {
            _errorMessage = 'Location permissions permanently denied. Go to settings to enable.';
        }
        else {
          _errorMessage = 'Failed to load weather: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  // --- FCM Configuration and Token Sending ---
  Future<void> _configureFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request permission for notifications (iOS & Web & Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications.');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print(
          'User granted provisional permission for notifications (provisional).');
    } else {
      print('User declined or has not accepted permission for notifications.');
      _showSnackBar('Notification permissions denied.', Colors.orange);
    }

    // 2. Get the FCM Token and send it to backend along with current location
    String? token = await messaging.getToken();
    if (token != null) {
      setState(() {
        _fcmToken = token;
      });
      print("FCM Token: $_fcmToken");
      // IMPORTANT: Only send with location if _currentPosition is already available.
      // Otherwise, _fetchWeatherData will handle sending it once location is ready.
      if (_currentPosition != null) {
        print('FCM token obtained and location already available. Sending token with location now.');
        await _sendFcmTokenToBackend(token, _currentPosition);
      } else {
        print('FCM token obtained, but location not yet available. Will send with location after _fetchWeatherData completes.');
      }
    }

    // 3. Listen for token refreshes and send the new token to backend
    messaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      setState(() {
        _fcmToken = newToken;
      });
      // Always send refreshed token with current position if available
      await _sendFcmTokenToBackend(newToken, _currentPosition);
    });

    // 4. Handle foreground messages (when the app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print(
            'Message also contained a notification: ${message.notification?.title}',
        );
        print('Message body: ${message.notification?.body}');

        _showSnackBar(
          '${message.notification?.title ?? 'New Weather Alert'}: ${message.notification?.body ?? ''}',
          Colors.blueAccent,
        );
      }
    });

    // 5. Handle messages when the app is opened from a background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background/terminated state by a notification!');
      print('Initial message: ${message.data}');
      _showSnackBar(
        'App opened by notification: ${message.notification?.title ?? 'Alert'}',
        Colors.green,
      );
      // Implement navigation logic here based on message.data if needed
    });
  }

  /// Sends the FCM token and device location to your backend server.
  Future<void> _sendFcmTokenToBackend(String token, Position? position) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // --- ADDED THIS DEBUG PRINT ---
    print('Sending to backend: FCM Token: $token, User ID: $userId, Lat: ${position?.latitude}, Lon: ${position?.longitude}');
    // --- END ADDED DEBUG PRINT ---

    try {
      final response = await http.post(
        // Ensure this points to your Vercel /api/index.js (which you named /api)
        Uri.parse(_backendApiEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{ // Use dynamic for latitude/longitude as they can be null
          'fcmToken': token,
          'userId': userId, // Link the token to a user
          'platform': defaultTargetPlatform.toString(),
          'latitude': position?.latitude,  // This is what's arriving as null
          'longitude': position?.longitude, // This is what's arriving as null
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token and location successfully sent to backend.');
      } else {
        print('Failed to send FCM token and location. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showSnackBar('Failed to register for notifications.', Colors.red);
      }
    } catch (e) {
      print('Error sending FCM token and location to backend: $e');
      _showSnackBar('Error registering for notifications: $e', Colors.red);
    }
  }

  // Helper to show SnackBars within the context of the Scaffold
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // --- Helper methods (Existing from your provided code, no changes needed) ---
  Icon _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('clear') ||
        condition.toLowerCase().contains('sunny')) {
      return Icon(Icons.wb_sunny, color: Colors.orange.shade300);
    } else if (condition.toLowerCase().contains('cloud')) {
      return Icon(Icons.cloud, color: Colors.grey.shade500);
    } else if (condition.toLowerCase().contains('rain')) {
      return Icon(Icons.cloudy_snowing, color: Colors.blue.shade500);
    } else if (condition.toLowerCase().contains('storm') ||
        condition.toLowerCase().contains('thunder')) {
      return Icon(Icons.thunderstorm, color: Colors.indigo.shade500);
    }
    return Icon(Icons.cloud_queue, color: Colors.grey); // Default
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String subText,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green.shade800, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: Colors.grey[700])),
            if (subText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _generateFarmingInsights(Map<String, dynamic> weatherData) {
    List<String> insights = [];

    final currentTemp = (weatherData['main']?['temp'] as num?)?.round();
    final humidity = (weatherData['main']?['humidity'] as num?)?.round();
    final windSpeedMps =
        (weatherData['wind']?['speed'] as num?)?.toDouble(); // m/s
    final windSpeedKmH =
        windSpeedMps != null ? (windSpeedMps * 3.6).round() : null;
    final weatherCondition =
        weatherData['weather']?[0]?['main']
            ?.toLowerCase(); // e.g., "clouds", "clear", "rain"
    final weatherDescription =
        weatherData['weather']?[0]?['description']?.toLowerCase();

    // Temperature-based insights
    if (currentTemp != null) {
      if (currentTemp > 30) {
        insights.add(
          'High temperatures (${currentTemp}°C) expected. Ensure plants are well-watered and consider afternoon shading for sensitive crops.',
        );
      } else if (currentTemp < 10) {
        insights.add(
          'Low temperatures (${currentTemp}°C) detected. Protect young plants from frost and cold stress.',
        );
      } else if (currentTemp >= 20 && currentTemp <= 28) {
        insights.add(
          'Optimal temperatures (${currentTemp}°C) for most common crops, supporting healthy growth.',
        );
      }
    }

    // Humidity-based insights
    if (humidity != null) {
      if (humidity > 80) {
        insights.add(
          'High humidity (${humidity}%) increases risk of fungal diseases. Ensure good air circulation around plants.',
        );
      } else if (humidity < 40) {
        insights.add(
          'Low humidity (${humidity}%) can lead to increased water demand. Monitor soil moisture closely.',
        );
      } else if (humidity >= 50 && humidity <= 70) {
        insights.add(
          'Ideal humidity (${humidity}%) for many crops, promoting efficient transpiration.',
        );
      }
    }

    // Wind-based insights
    if (windSpeedKmH != null) {
      if (windSpeedKmH > 25) {
        insights.add(
          'Strong winds (${windSpeedKmH} km/h) today. Secure taller plants and consider windbreaks for protection.',
        );
      } else if (windSpeedKmH <= 10) {
        insights.add(
          'Light winds (${windSpeedKmH} km/h) are perfect for natural pollination and avoiding plant stress.',
        );
      }
    }

    // Precipitation-based insights (from current weather condition)
    if (weatherCondition != null) {
      if (weatherCondition.contains('rain') ||
          weatherDescription.contains('rain')) {
        insights.add(
          'Rainfall expected. Check drainage systems and consider pausing irrigation.',
        );
      } else if (weatherCondition.contains('clear') ||
          weatherCondition.contains('sunny')) {
        insights.add(
          'Clear skies and sun today. Maximize sunlight exposure for plants that love full sun.',
        );
        if (currentTemp != null && currentTemp > 25) {
            insights.add('With clear skies and high temperatures, consider increased irrigation frequency.');
        }
      } else if (weatherCondition.contains('snow')) {
        insights.add('Snowfall detected. Protect crops from extreme cold and monitor for freeze damage.');
      }
    }

    // Fallback if no specific insights match
    if (insights.isEmpty) {
      insights.add(
        'Current weather conditions are generally stable for farming activities.',
      );
    }

    return insights;
  }

  Widget _buildInsightBox(String text, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> weatherData) {
    final insights = _generateFarmingInsights(
      weatherData,
    ); // Pass weatherData to generator

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Farming Insights',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...insights.map((insightText) {
            Color bgColor;
            if (insightText.toLowerCase().contains('optimal') ||
                insightText.toLowerCase().contains('perfect') ||
                insightText.toLowerCase().contains('ideal')) {
              bgColor = Colors.green.shade50;
            } else if (insightText.toLowerCase().contains('high temp') ||
                insightText.toLowerCase().contains('low temp') ||
                insightText.toLowerCase().contains('strong winds') ||
                insightText.toLowerCase().contains('risk') ||
                insightText.toLowerCase().contains('consider')) {
              bgColor = Colors.orange.shade50;
            } else {
              bgColor = Colors.blue.shade50;
            }
            return _buildInsightBox(insightText, bgColor);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastSection(Map<String, dynamic> forecastData) {
    if (forecastData['list'] == null) {
      return const SizedBox.shrink();
    }

    final Map<String, List<Map<String, dynamic>>> dailyForecasts = {};
    for (var item in forecastData['list']) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final day = _getWeekday(dateTime.weekday);
      if (!dailyForecasts.containsKey(day)) {
        dailyForecasts[day] = [];
      }
      dailyForecasts[day]?.add(item);
    }

    final List<String> orderedDays = [];
    for (int i = 0; i < 5; i++) {
      final day = _getWeekday(DateTime.now().add(Duration(days: i)).weekday);
      orderedDays.add(day);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5-Day Forecast',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...orderedDays.map((day) {
            final forecastsForDay = dailyForecasts[day];
            if (forecastsForDay == null || forecastsForDay.isEmpty) {
              return const SizedBox.shrink();
            }
            double maxTemp = -double.infinity;
            double minTemp = double.infinity;
            String mainCondition = '';
            int totalRainProbability = 0;
            int count = 0;

            for (var f in forecastsForDay) {
              final tempMax = (f['main']?['temp_max'] as num?)?.toDouble();
              final tempMin = (f['main']?['temp_min'] as num?)?.toDouble();
              final pop = (f['pop'] as num?)?.toDouble();

              if (tempMax != null) maxTemp = max(maxTemp, tempMax);
              if (tempMin != null) minTemp = min(minTemp, tempMin);
              if (pop != null) totalRainProbability += (pop * 100).round();
              count++;
            }

            if (forecastsForDay.isNotEmpty) {
              mainCondition =
                  forecastsForDay[0]['weather']?[0]?['description'] ?? 'N/A';
            }

            return _buildForecastTile(
              day,
              mainCondition,
              '${maxTemp.round()}°',
              '${minTemp.round()}°',
              '${count > 0 ? (totalRainProbability ~/ count) : 0}%',
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastTile(
    String day,
    String condition,
    String high,
    String low,
    String rain,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      leading: _getWeatherIcon(condition),
      dense: true,
      title: Text(
        day,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(condition, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$high / $low',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$rain rain',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWeatherData, // Refreshes weather (and location)
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_errorMessage!.contains('permissions denied')) {
                              await Geolocator.openAppSettings(); // Open app settings
                            } else if (_errorMessage!.contains('services are disabled')) {
                              await Geolocator.openLocationSettings(); // Open location settings
                            }
                            _fetchWeatherData(); // Retry fetching weather
                          },
                          child: Text(
                            _errorMessage!.contains('permissions denied') || _errorMessage!.contains('services are disabled')
                                ? 'Open Settings'
                                : 'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _currentWeatherData == null
              ? const Center(child: Text('No current weather data available.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _currentWeatherData!['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentWeatherData!['weather']?[0]?['description'] ??
                                  'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(_currentWeatherData!['main']?['temp'] as num?)?.round() ?? 'N/A'}°C',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (_currentWeatherData!['weather']?[0]?['icon'] !=
                                null)
                              Image.network(
                                'http://openweathermap.org/img/wn/${_currentWeatherData!['weather']?[0]?['icon']}@2x.png',
                                width: 80,
                                height: 80,
                              ),
                            Text(
                              'Feels like ${(_currentWeatherData!['main']?['feels_like'] as num?)?.round() ?? 'N/A'}°C',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatCard(
                            'Humidity',
                            '${(_currentWeatherData!['main']?['humidity'] as num?)?.round() ?? 'N/A'}%',
                            Icons.water_drop,
                            '',
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            'Wind Speed',
                            '${((_currentWeatherData!['wind']?['speed'] as num?) != null ? (_currentWeatherData!['wind']['speed']! * 3.6).round() : 'N/A')} km/h',
                            Icons.air,
                            '',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInsightsSection(_currentWeatherData!),
                      const SizedBox(height: 20),
                      FutureBuilder<Map<String, dynamic>>(
                        // Pass current position to fetchForecastData
                        future: _currentPosition != null ? weather_api.fetchForecastData(
                          latitude: _currentPosition!.latitude,
                          longitude: _currentPosition!.longitude,
                        ) : Future.value(null), // Handle case where location is not yet available
                        builder: (context, forecastSnapshot) {
                          if (forecastSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (forecastSnapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error loading forecast: ${forecastSnapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                          if (!forecastSnapshot.hasData ||
                              forecastSnapshot.data == null) {
                            return const Center(
                              child: Text('No forecast data available.'),
                            );
                          }
                          return _buildForecastSection(forecastSnapshot.data!);
                        },
                      ),
                      const SizedBox(height: 20),
                      
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}