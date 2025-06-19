import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'newplant.dart';
import 'plants.dart';
import 'weather.dart';

class Task {
  String title;
  String description;
  bool isDone;
  DateTime dueDate;

  Task({
    required this.title,
    required this.description,
    required this.isDone,
    required this.dueDate,
  });
}

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final List<Task> tasks = [
    Task(
      title: "Buy Seeds",
      description: "Kales & Spinach",
      isDone: false,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Task(
      title: "Water Crops",
      description: "Early morning",
      isDone: false,
      dueDate: DateTime.now(),
    ),
    Task(
      title: "Check Pests",
      description: "Inspect for aphids",
      isDone: true,
      dueDate: DateTime.now(),
    ),
    Task(
      title: "Harvest Tomatoes",
      description: "Fully ripened",
      isDone: false,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
  ];

  Future<String> fetchTipOfTheDay() async {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    final tipQuery =
        await FirebaseFirestore.instance
            .collection("Tips")
            .where("date", isEqualTo: todayStr)
            .get();

    if (tipQuery.docs.isNotEmpty) {
      return tipQuery.docs.first.data()['Tip'];
    } else {
      final randomTip =
          await FirebaseFirestore.instance.collection("Tips").limit(1).get();
      return randomTip.docs.first.data()['Tip'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdueTasks =
        tasks
            .where((task) => task.dueDate.isBefore(now) && !task.isDone)
            .toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
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

              // Pending tasks and weather alerts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardWithTasks("Pending Tasks", overdueTasks),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WeatherPage()),
                      );
                    },
                    child: _buildCard("Alert weather/\nbreakouts"),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              Text(
                'Hello Tracy,',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              // Tip of the day
              FutureBuilder<String>(
                future: fetchTipOfTheDay(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Loading tip...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    );
                  } else if (snapshot.hasError) {
                    print("🔥 Snapshot error: ${snapshot.error}");
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
