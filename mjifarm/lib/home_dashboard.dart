import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'newplant.dart'; // Import this
import 'plants.dart'; // Optional if routing directly
import 'weather.dart';

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdueTasks =
        tasks
            .where((task) => task.dueDate.isBefore(now) && !task.isDone)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
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

                // Pending tasks and weather alerts
                Row(
                  children: [
                    _buildCard('Pending task'),

                    //if this card is pressed, navigate to the weather page
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
                SizedBox(height: 25),

                // Greeting
                Text(
                  'Hello Tracy,',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                // Tip of the Day
                FutureBuilder<String>(
                  future: fetchTipOfTheDay(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        "🌱 Loading tip...",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    } else if (snapshot.hasError) {
                      return Text("⚠️ Error: ${snapshot.error}");
                    } else {
                      return Card(
                        color: Colors.green.shade50,
                        margin: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "🌿 ${snapshot.data}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),

                // In the Farm
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Plant Circles
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchPlants(),
                  builder: (context, snapshot) {
                    final plants = snapshot.data ?? [];
                    return SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFarmCircle(
                            context,
                            icon: Icons.add,
                            label: 'Add',
                          ),
                          ...plants.map((plant) {
                            return _buildFarmCircle(
                              context,
                              image: plant['imagePath'],
                              label: plant['name'],
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),

                // Trending
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Trending practices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                const SizedBox(height: 20),

                // Quick Access
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContactExpertPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.support_agent),
                      label: Text("Contact Experts"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PestAlertPage()),
                        );
                      },
                      icon: Icon(Icons.bug_report),
                      label: Text("Pest Alerts"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          140,
                          236,
                          145,
                        ),
                        foregroundColor: const Color.fromARGB(255, 11, 11, 11),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildCardWithTasks(String title, List<Task> overdueTasks) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffb0e8b2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (overdueTasks.isEmpty)
            const Text("No pending tasks", style: TextStyle(fontSize: 12))
          else
            ...overdueTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "• ${task.title}",
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildFarmCircle(
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
                        child: Image.network(
                          image,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Icon(Icons.broken_image),
                        ),
                      )
                      : Icon(Icons.grass, color: Colors.green),
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
