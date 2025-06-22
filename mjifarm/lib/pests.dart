import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart';

class PestAlert {
  final String type;
  final String title;
  final String description;
  final String location;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final LatLng coordinates; 

  PestAlert({
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.icon,
    required this.color,
    required this.coordinates, 
  });
}

class PestAlertsPage extends StatelessWidget {

  final List<PestAlert> alerts = [
    PestAlert(
      type: "GARDEN PEST",
      title: "Aphid Infestation Detected",
      description: "High concentration of aphids found in rooftop gardens.",
      location: "Kibera Rooftops",
      timeAgo: "2 hours ago",
      icon: Icons.bug_report,
      color: Colors.orange,
      coordinates: LatLng(-1.3039, 36.7822), // Example: Near Kibera, Nairobi
    ),
    PestAlert(
      type: "STRUCTURAL PEST",
      title: "Termite Activity Warning",
      description: "Active termite zones found near compost bins.",
      location: "Westlands Block",
      timeAgo: "5 hours ago",
      icon: Icons.warning,
      color: Colors.redAccent,
      coordinates: LatLng(-1.2676, 36.8049), // Example: Westlands, Nairobi
    ),
    PestAlert(
      type: "VECTOR CONTROL",
      title: "Mosquito Breeding Sites",
      description: "Standing water around potted plants identified.",
      location: "Kasarani East",
      timeAgo: "1 day ago",
      icon: Icons.bug_report_outlined,
      color: Colors.green,
      coordinates: LatLng(-1.2384, 36.9205), // Example: Kasarani, Nairobi
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Urban Pest Alerts"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          _buildMapSection(), // This will now render the map
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                return _buildPestCard(alerts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
  
    double avgLat =
        alerts.map((a) => a.coordinates.latitude).reduce((a, b) => a + b) /
        alerts.length;
    double avgLng =
        alerts.map((a) => a.coordinates.longitude).reduce((a, b) => a + b) /
        alerts.length;
    LatLng initialCenter = LatLng(avgLat, avgLng);

   

    return Container(
      margin: const EdgeInsets.all(12),
      height: 250, // Increased height for better map view
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ), // Optional: add border
      ),
      child: ClipRRect(
        // Clip to apply borderRadius
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom:
                10.0, 
            minZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
             
              userAgentPackageName:
                  'com.mjifarms.app', 
            ),
            MarkerLayer(
              markers:
                  alerts.map((alert) {
                    return Marker(
                      width: 40.0,
                      height: 40.0,
                      point: alert.coordinates,
                      child: Tooltip(
                        // Optional: show text on long press/hover
                        message: alert.title,
                        child: Icon(alert.icon, color: alert.color, size: 30.0),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestCard(PestAlert alert) {
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
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add action
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
