// lib/pages/pest_alerts_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pest_details.dart'; // NEW: Import the details page

// Define a threshold for "nearby" alerts (e.g., 5 km)
const double _nearbyDistanceKm = 5.0;

class PestAlert {
  final String type;
  final String title;
  final String description;
  final String location;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final LatLng coordinates;
  double? distanceKm; // New field to store distance from current location

  PestAlert({
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.icon,
    required this.color,
    required this.coordinates,
    this.distanceKm, // Make it optional
  });
}

class PestAlertsPage extends StatefulWidget {
  const PestAlertsPage({super.key});

  @override
  State<PestAlertsPage> createState() => _PestAlertsPageState();
}

class _PestAlertsPageState extends State<PestAlertsPage> {
  // Hardcoded alerts for demonstration, now tailored for urban farming.
  // In a real app, these would come from a backend.
  List<PestAlert> _pestAlerts = [
    PestAlert(
      type: "GARDEN PEST",
      title: "Aphid Infestation Detected",
      description:
          "High concentration of aphids found on kale and spinach leaves in urban gardens.",
      location: "Kibera Rooftops",
      timeAgo: "2 hours ago",
      icon: Icons.bug_report,
      color: Colors.orange,
      coordinates: LatLng(-1.3039, 36.7822), // Example: Near Kibera, Nairobi
    ),
    PestAlert(
      type: "STRUCTURAL PEST",
      title: "Termite Activity Warning",
      description:
          "Active termite zones found near compost bins and wooden raised beds.",
      location: "Westlands Block",
      timeAgo: "5 hours ago",
      icon: Icons.warning,
      color: Colors.redAccent,
      coordinates: LatLng(-1.2676, 36.8049), // Example: Westlands, Nairobi
    ),
    PestAlert(
      type: "VECTOR CONTROL",
      title: "Mosquito Breeding Sites",
      description:
          "Standing water around potted plants and rainwater harvesting barrels identified.",
      location: "Kasarani East",
      timeAgo: "1 day ago",
      icon: Icons.bug_report_outlined,
      color: Colors.green,
      coordinates: LatLng(-1.2384, 36.9205), // Example: Kasarani, Nairobi
    ),
    PestAlert(
      type: "GARDEN PEST",
      title: "Whitefly Outbreak Alert",
      description:
          "Significant whitefly populations affecting tomato and bean plants.",
      location: "Nairobi West Community Garden",
      timeAgo: "3 hours ago",
      icon: Icons.grass, // Using a generic plant/bug icon
      color: Colors.purple,
      coordinates: LatLng(-1.310556, 36.819167), // Coordinates for Nairobi West
    ),
    PestAlert(
      type: "SOIL PEST",
      title: "Fungus Gnat Infestation",
      description:
          "Increased presence of fungus gnats in indoor herb gardens due to overwatering.",
      location: "Kilimani Apartments",
      timeAgo: "6 hours ago",
      icon: Icons.park, // Could represent indoor plant
      color: Colors.lightBlue,
      coordinates: LatLng(-1.2917, 36.7847), // Example: Kilimani, Nairobi
    ),
  ];

  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition; // Device's current location

  // Backend endpoint to send device location for pest proximity checking
  static const String _backendLocationUpdateEndpoint =
      "https://mjifarms-pests.vercel.app/api/send-pest-alert"; // Ensure this matches your Vercel URL

  @override
  void initState() {
    super.initState();
    _fetchPestAlertsAndLocation();
  }

  /// Determines the current position (latitude and longitude) of the device.
  /// This function handles permissions and ensures location services are enabled.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Permissions are granted, continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  // --- Fetch Pest Alerts and Device Location ---
  Future<void> _fetchPestAlertsAndLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentPosition = await _determinePosition();
      print(
        'PestAlertsPage: Fetched device location: Lat ${_currentPosition!.latitude}, Lon ${_currentPosition!.longitude}',
      );

      // Calculate distances for each alert
      List<PestAlert> updatedAlerts =
          _pestAlerts.map((alert) {
            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              alert.coordinates.latitude,
              alert.coordinates.longitude,
            );
            // Convert meters to kilometers and round to 2 decimal places
            alert.distanceKm = double.parse(
              (distance / 1000).toStringAsFixed(2),
            );
            return alert;
          }).toList();

      // Sort alerts by distance (nearby ones first)
      updatedAlerts.sort((a, b) {
        if (a.distanceKm == null || b.distanceKm == null) return 0;
        return a.distanceKm!.compareTo(b.distanceKm!);
      });

      // --- Send current location to backend for server-side proximity checks ---
      await _sendDeviceLocationToBackend(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _pestAlerts = updatedAlerts;
        _isLoading = false;
      });
    } catch (e) {
      print('PestAlertsPage: Error fetching location or processing alerts: $e');
      setState(() {
        if (e.toString().contains('Location services are disabled')) {
          _errorMessage = 'Location services are disabled. Please enable them.';
        } else if (e.toString().contains('Location permissions are denied')) {
          _errorMessage =
              'Location permissions denied. Please grant permission in app settings.';
        } else if (e.toString().contains('permanently denied')) {
          _errorMessage =
              'Location permissions permanently denied. Go to settings to enable.';
        } else {
          _errorMessage = 'Failed to load pest alerts: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  /// Sends the device's current location to a backend endpoint.
  /// This is used by the backend to determine if this device (and others)
  /// should receive pest outbreak notifications.
  Future<void> _sendDeviceLocationToBackend(
    double latitude,
    double longitude,
  ) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final String? fcmToken =
        await FirebaseMessaging.instance.getToken(); // Get current FCM token

    if (userId == null || fcmToken == null) {
      print(
        'PestAlertsPage: Cannot send location to backend: User not logged in or FCM token not available.',
      );
      return;
    }

    print(
      'PestAlertsPage: Sending device location to backend: Lat $latitude, Lon $longitude, UserID: $userId, FCM Token: $fcmToken',
    );

    try {
      final response = await http.post(
        Uri.parse(_backendLocationUpdateEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
          'fcmToken': fcmToken,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(), // Add timestamp
        }),
      );

      if (response.statusCode == 200) {
        print(
          'PestAlertsPage: Device location successfully sent to backend for pest monitoring.',
        );
      } else {
        print(
          'PestAlertsPage: Failed to send device location to backend. Status: ${response.statusCode}',
        );
        print('PestAlertsPage: Response body: ${response.body}');
      }
    } catch (e) {
      print('PestAlertsPage: Error sending device location to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Urban Pest Alerts"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _fetchPestAlertsAndLocation, // Refreshes alerts and location
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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
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
                            await Geolocator.openAppSettings();
                          } else if (_errorMessage!.contains(
                            'services are disabled',
                          )) {
                            await Geolocator.openLocationSettings();
                          }
                          _fetchPestAlertsAndLocation(); // Retry
                        },
                        child: Text(
                          _errorMessage!.contains('permissions denied') ||
                                  _errorMessage!.contains(
                                    'services are disabled',
                                  )
                              ? 'Open Settings'
                              : 'Retry',
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  _buildMapSection(), // This will now render the map
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pestAlerts.length,
                      itemBuilder: (context, index) {
                        return _buildPestCard(_pestAlerts[index]);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMapSection() {
    // Determine the initial center for the map
    LatLng initialCenter;
    double initialZoom = 10.0; // Default zoom for Nairobi area

    if (_currentPosition != null) {
      initialCenter = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      initialZoom = 12.0; // Zoom in more if user's location is known
    } else if (_pestAlerts.isNotEmpty) {
      // If no current position, center on the average of pest alerts
      double avgLat =
          _pestAlerts
              .map((a) => a.coordinates.latitude)
              .reduce((a, b) => a + b) /
          _pestAlerts.length;
      double avgLng =
          _pestAlerts
              .map((a) => a.coordinates.longitude)
              .reduce((a, b) => a + b) /
          _pestAlerts.length;
      initialCenter = LatLng(avgLat, avgLng);
    } else {
      // Default to Nairobi if no data
      initialCenter = LatLng(-1.286389, 36.817223); // Nairobi coordinates
    }

    List<Marker> markers =
        _pestAlerts.map((alert) {
          return Marker(
            width: 40.0,
            height: 40.0,
            point: alert.coordinates,
            child: Tooltip(
              message: alert.title,
              child: Icon(alert.icon, color: alert.color, size: 30.0),
            ),
          );
        }).toList();

    // Add a marker for the current user's location if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          child: Tooltip(
            message: "Your Location",
            child: Icon(
              Icons.person_pin_circle,
              color: Colors.blue.shade700,
              size: 35.0,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      height: 250, // Increased height for better map view
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mjifarms.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildPestCard(PestAlert alert) {
    bool isNearby =
        alert.distanceKm != null && alert.distanceKm! <= _nearbyDistanceKm;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(alert.icon, color: alert.color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      alert.type,
                      style: TextStyle(
                        color: alert.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(alert.timeAgo, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(alert.description),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  alert.location,
                  style: TextStyle(color: Colors.grey.shade700),
                ),                
                const SizedBox(width: 4),

                if (alert.distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isNearby ? Icons.near_me : Icons.alt_route,
                    size: 16,
                    color: isNearby ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isNearby
                        ? 'Nearby (${alert.distanceKm} km)'
                        : '${alert.distanceKm} km away',
                    style: TextStyle(
                      color: isNearby ? Colors.green : Colors.grey.shade700,
                      fontWeight:
                          isNearby ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the PestDetailsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PestDetailsPage(pestAlert: alert),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: alert.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Select"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
