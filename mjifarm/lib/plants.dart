import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'plantdetails.dart'; // Make sure this import matches your file structure

class MyPlantsPage extends StatelessWidget {
  const MyPlantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [BackButton(), Icon(Icons.more_vert)],
              ),
              const SizedBox(height: 10),
              const Text(
                'My Plants',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search a plant',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.green[700]),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Plant list from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('plants')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No plants added yet.'));
                    }

                    final plants = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        final plant =
                            plants[index].data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlantDetailsPage(
                                      name: plant['name'] ?? 'Unnamed Plant',
                                      imagePath:
                                          plant['imageUrl'] ??
                                          'assets/plant.png', // Fallback asset
                                      growthStatus: _determineGrowthStatus(
                                        plant,
                                      ),
                                      growthPercentage:
                                          _calculateGrowthPercentage(plant),
                                      harvestDate:
                                          plant['maturityDate'] ?? 'Unknown',
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade100,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    plant['imageUrl'] ??
                                        'https://cdn-icons-png.flaticon.com/512/7662/7662059.png',
                                  ),
                                  radius: 30,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant['name'] ?? 'Unnamed Plant',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _daysUntilHarvestText(plant),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/newplant',
          ); // Define route in main.dart
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _daysUntilHarvestText(Map<String, dynamic> plant) {
    try {
      final maturityDate = DateTime.parse(plant['maturityDate']);
      final now = DateTime.now();
      final daysLeft = maturityDate.difference(now).inDays;
      return daysLeft >= 0
          ? '$daysLeft days until Harvest'
          : 'Ready to harvest!';
    } catch (e) {
      return 'Unknown harvest date';
    }
  }

  String _determineGrowthStatus(Map<String, dynamic> plant) {
    try {
      final now = DateTime.now();
      final planting = DateTime.parse(plant['plantingDate']);
      final maturity = DateTime.parse(plant['maturityDate']);
      final totalDays = maturity.difference(planting).inDays;
      final daysPassed = now.difference(planting).inDays;

      if (daysPassed <= 0) return 'Just Planted';
      if (daysPassed >= totalDays) return 'Ready';

      final percent = (daysPassed / totalDays) * 100;
      if (percent < 30) return 'Growing';
      if (percent < 80) return 'Maturing';
      return 'Almost Ready';
    } catch (_) {
      return 'Unknown';
    }
  }

  int _calculateGrowthPercentage(Map<String, dynamic> plant) {
    try {
      final now = DateTime.now();
      final planting = DateTime.parse(plant['plantingDate']);
      final maturity = DateTime.parse(plant['maturityDate']);
      final totalDays = maturity.difference(planting).inDays;
      final daysPassed = now.difference(planting).inDays;

      final percent = ((daysPassed / totalDays) * 100).clamp(0, 100);
      return percent.floor();
    } catch (_) {
      return 0;
    }
  }
}
