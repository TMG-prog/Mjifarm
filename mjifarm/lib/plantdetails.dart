import 'package:flutter/material.dart';
import 'dart:convert'; // Import for base64Decode

class PlantDetailsPage extends StatelessWidget {
  final String name;
  final String imagePath; // Can be asset path or base64 data URI
  final String growthStatus;
  final int growthPercentage;
  final String harvestDate;
  final String? gardenName; // New field
  final String? container; // New field
  final String? category; // New field
  final String? plantingDate; // New field

  const PlantDetailsPage({
    super.key,
    required this.name,
    required this.imagePath,
    required this.growthStatus,
    required this.growthPercentage,
    required this.harvestDate,
    this.gardenName, // Make these nullable as they might not always be present or needed for all calls
    this.container,
    this.category,
    this.plantingDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            Text(
              'Harvest on ${harvestDate.split('T')[0]}', // Display only date part
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 30),
            _buildProgressPlaceholder(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    ImageProvider imageProvider;
    if (imagePath.startsWith('data:image')) {
      // Decode base64 image data
      final String base64String = imagePath.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64String));
    } else {
      // Assume it's an asset path
      imageProvider = AssetImage(imagePath);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFd4f3d2), Color.fromARGB(255, 189, 230, 185)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Align(alignment: Alignment.topLeft, child: BackButton(
            onPressed: () => Navigator.pop(context), // Ensure back button works
          )),
          CircleAvatar(radius: 50, backgroundImage: imageProvider), // Use dynamic imageProvider
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            '$growthPercentage%',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text('$growthStatus 🌱'),
            backgroundColor: Colors.green.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Collect all info cards dynamically
    List<Widget> infoCards = [
      _buildInfoCard(Icons.thermostat, '25%', 'Temperature'),
      _buildInfoCard(Icons.water_drop, 'Abundant', 'Water'),
      _buildInfoCard(Icons.wb_sunny, 'High', 'Sun Light'),
      _buildInfoCard(Icons.grass, 'Medium', 'Soil'),
    ];

    if (gardenName != null && gardenName!.isNotEmpty) {
      infoCards.add(_buildInfoCard(Icons.location_on, gardenName!, 'Garden'));
    }
    if (category != null && category!.isNotEmpty) {
      infoCards.add(_buildInfoCard(Icons.local_florist, category!, 'Category'));
    }
    if (container != null && container!.isNotEmpty) {
      infoCards.add(_buildInfoCard(Icons.inventory_2, container!, 'Container'));
    }
    if (plantingDate != null && plantingDate!.isNotEmpty) {
      infoCards.add(_buildInfoCard(Icons.calendar_today, plantingDate!.split('T')[0], 'Planting Date'));
    }


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(), // Use const for better performance
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: infoCards, // Use the dynamically built list
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green.shade100,
            child: Icon(icon, size: 28, color: Colors.green.shade800),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildProgressPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text(
                'Progress Graph Placeholder',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
