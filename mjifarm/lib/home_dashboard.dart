import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'newplant.dart';
import 'plants.dart';
import 'weather.dart';

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pending task and weather cards
            Row(
              children: [
                _buildCard('Pending task'),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WeatherPage()),
                    );
                  },
                  child: _buildCard('Weather'),
                ),
              ],
            ),

            const SizedBox(height: 25),
            const Text(
              'Hello Tracy,',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // Tip of the day from Firebase
            FutureBuilder<DatabaseEvent>(
              future: FirebaseDatabase.instance.ref('tips/today').once(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Loading tip...",
                    style: TextStyle(color: Colors.black54),
                  );
                } else if (snapshot.hasError) {
                  return const Text(
                    "Error loading tip",
                    style: TextStyle(color: Colors.red),
                  );
                } else if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Text(
                    "No tip available",
                    style: TextStyle(color: Colors.black54),
                  );
                }

                final tip = snapshot.data!.snapshot.value.toString();
                return Text(tip, style: const TextStyle(color: Colors.black54));
              },
            ),

            const SizedBox(height: 20),

            // In the Farm section
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyPlantsPage()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'In the Farm',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFarmCircle(context, icon: Icons.add, label: 'Add'),
                ],
              ),
            ),

            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Trending practices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTrendingCard(
                    'assets/sample1.jpg',
                    'Compost Tips',
                    'Best composting for urban farms',
                  ),
                  _buildTrendingCard(
                    'assets/sample2.jpg',
                    'Irrigation Hacks',
                    'Low-budget watering system',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffb0e8b2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text(title, textAlign: TextAlign.center)),
    );
  }

  Widget _buildFarmCircle(
    BuildContext context, {
    IconData? icon,
    String? image,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'Add') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewPlantPage()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child:
                  icon != null
                      ? Icon(icon, size: 30, color: Colors.black)
                      : image != null && image.isNotEmpty
                      ? ClipOval(
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          height: 60,
                          width: 60,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static Widget _buildTrendingCard(String image, String brand, String label) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              image,
              height: 100,
              width: 130,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    height: 100,
                    width: 130,
                    child: const Icon(Icons.broken_image),
                  ),
            ),
          ),
          const SizedBox(height: 5),
          Text(brand, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
