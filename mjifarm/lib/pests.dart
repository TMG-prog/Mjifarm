import 'package:flutter/material.dart';

class PestAlert {
  final String type;
  final String title;
  final String description;
  final String location;
  final String timeAgo;
  final IconData icon;
  final Color color;

  PestAlert({
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.icon,
    required this.color,
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
    ),
    PestAlert(
      type: "STRUCTURAL PEST",
      title: "Termite Activity Warning",
      description: "Active termite zones found near compost bins.",
      location: "Westlands Block",
      timeAgo: "5 hours ago",
      icon: Icons.warning,
      color: Colors.redAccent,
    ),
    PestAlert(
      type: "VECTOR CONTROL",
      title: "Mosquito Breeding Sites",
      description: "Standing water around potted plants identified.",
      location: "Kasarani East",
      timeAgo: "1 day ago",
      icon: Icons.bug_report_outlined,
      color: Colors.green,
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
          _buildMapSection(),
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
    return Container(
      margin: const EdgeInsets.all(12),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: AssetImage(
            'assets/map_placeholder.png',
          ), // Replace with real map or static
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.topRight,
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Live",
          style: TextStyle(fontWeight: FontWeight.bold),
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
