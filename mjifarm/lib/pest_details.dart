// lib/pages/pest_details_page.dart
import 'package:flutter/material.dart';
import '../pests.dart'; // Import PestAlert for type safety

class PestDetailsPage extends StatelessWidget {
  final PestAlert pestAlert;

  const PestDetailsPage({super.key, required this.pestAlert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pestAlert.title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                pestAlert.icon,
                size: 80,
                color: pestAlert.color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pestAlert.type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pestAlert.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pestAlert.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  pestAlert.location,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                if (pestAlert.distanceKm != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    pestAlert.distanceKm! <= 5.0 ? Icons.near_me : Icons.alt_route,
                    size: 20,
                    color: pestAlert.distanceKm! <= 5.0 ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pestAlert.distanceKm! <= 5.0
                        ? 'Nearby (${pestAlert.distanceKm} km)'
                        : '${pestAlert.distanceKm} km away',
                    style: TextStyle(
                      fontSize: 16,
                      color: pestAlert.distanceKm! <= 5.0 ? Colors.green : Colors.grey.shade700,
                      fontWeight: pestAlert.distanceKm! <= 5.0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reported: ${pestAlert.timeAgo}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 30, thickness: 1),
            const Text(
              'Pest Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              pestAlert.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Add more specific details or actions here
            const Text(
              'Recommended Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Example of dynamic content based on pest type
            _buildRecommendedActions(pestAlert.type),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Simulate reporting user's action or closing
                  Navigator.pop(context); // Go back to the previous page
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Reviewed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedActions(String pestType) {
    List<String> actions = [];
    switch (pestType) {
      case "GARDEN PEST":
        actions = [
          "Inspect plants daily for early signs.",
          "Use neem oil spray or insecticidal soap.",
          "Introduce beneficial insects like ladybugs.",
          "Prune affected leaves to prevent spread.",
          "Maintain good garden hygiene."
        ];
        break;
      case "STRUCTURAL PEST":
        actions = [
          "Check for mud tubes or wood damage regularly.",
          "Remove wood debris near structures.",
          "Ensure proper drainage around foundations.",
          "Consider professional pest control for severe infestations."
        ];
        break;
      case "VECTOR CONTROL":
        actions = [
          "Eliminate standing water sources (pots, tires, gutters).",
          "Clean rainwater harvesting barrels regularly.",
          "Use mosquito nets and repellents.",
          "Introduce mosquito fish to water features if applicable."
        ];
        break;
      case "SOIL PEST":
        actions = [
          "Allow soil to dry out between waterings.",
          "Use yellow sticky traps to catch adult gnats.",
          "Apply Bti (Bacillus thuringiensis israelensis) to soil.",
          "Improve soil aeration and drainage."
        ];
        break;
      default:
        actions = ["Consult a local agricultural extension office for specific advice."];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions
          .map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: pestAlert.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}