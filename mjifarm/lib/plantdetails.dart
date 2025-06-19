import 'package:flutter/material.dart';

class PlantDetailsPage extends StatelessWidget {
  final String name;
  final String imagePath;
  final String growthStatus;
  final int growthPercentage;
  final String harvestDate;

  const PlantDetailsPage({
    super.key,
    required this.name,
    required this.imagePath,
    required this.growthStatus,
    required this.growthPercentage,
    required this.harvestDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 10),
            Text(
              'Harvest on $harvestDate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            _buildStatsGrid(),
            SizedBox(height: 30),
            _buildProgressPlaceholder(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Align(alignment: Alignment.topLeft, child: BackButton()),
          CircleAvatar(radius: 50, backgroundImage: AssetImage(imagePath)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildInfoCard(Icons.thermostat, '25%', 'Temperature'),
          _buildInfoCard(Icons.water_drop, 'Abundant', 'Water'),
          _buildInfoCard(Icons.wb_sunny, 'High', 'Sun Light'),
          _buildInfoCard(Icons.grass, 'Medium', 'Soil'),
        ],
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
