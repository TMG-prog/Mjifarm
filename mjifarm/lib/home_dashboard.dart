import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:mjifarm/weather.dart' show getTodayWeatherSummary, WeatherData;
import 'package:mjifarm/reminder.dart';
import 'package:mjifarm/pests.dart';
import 'package:mjifarm/plants.dart';
import 'package:mjifarm/newplant.dart';
import 'package:mjifarm/article.dart';
import 'package:mjifarm/weather.dart';
import 'package:mjifarm/farmer_features/expert_selection.dart';

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final WeatherData weatherSummary = getTodayWeatherSummary();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Search bar
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

            //  Tasks and Weather cards
            Row(
              children: [
                // Today’s Tasks Card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReminderPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xffb0e8b2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Tasks",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<DatabaseEvent>(
                            future:
                                FirebaseDatabase.instance
                                    .ref(
                                      'tasks/${FirebaseAuth.instance.currentUser?.uid}',
                                    )
                                    .once(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data?.snapshot.value == null) {
                                return const Text("No tasks today.");
                              }

                              final data = Map<String, dynamic>.from(
                                snapshot.data!.snapshot.value as Map,
                              );

                              final today = DateTime.now();
                              final todayTasks =
                                  data.values
                                      .map((e) => Map<String, dynamic>.from(e))
                                      .where((task) {
                                        final due = DateTime.tryParse(
                                          task['dueDate'] ?? '',
                                        );
                                        return due != null &&
                                            due.year == today.year &&
                                            due.month == today.month &&
                                            due.day == today.day;
                                      })
                                      .take(2)
                                      .toList();

                              if (todayTasks.isEmpty) {
                                return const Text("No tasks today.");
                              }

                              return Wrap(
                                spacing: 8,
                                children:
                                    todayTasks.map((task) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        child: Text(
                                          task['title'] ?? '',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Weather Card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WeatherPage()),
                      );
                    },
                    child: _buildCard(
                      'Weather',
                      subtitle:
                          '${weatherSummary.temperature}, ${weatherSummary.condition}',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Hello Tracy,',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // 🌞 Tip of the Day
            FutureBuilder<DatabaseEvent>(
              future: FirebaseDatabase.instance.ref('tips/$todayDate').once(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Loading tip...",
                    style: TextStyle(color: Colors.black54),
                  );
                }
                if (snapshot.hasError) {
                  return const Text(
                    "Error loading tip",
                    style: TextStyle(color: Colors.red),
                  );
                }

                final tip = snapshot.data?.snapshot.value?.toString();
                if (tip == null || tip.isEmpty) {
                  return _buildTipBox(
                    "No tip available for today.",
                    isEmpty: true,
                  );
                }

                return _buildTipBox(tip);
              },
            ),

            const SizedBox(height: 20),

            //  In the Farm Section
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

            //  Trending Articles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Trending articles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 180,
              child: FutureBuilder<DatabaseEvent>(
                future: FirebaseDatabase.instance.ref('articles').once(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text("No trending articles found."),
                    );
                  }

                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  final trendingArticles =
                      data.entries
                          .map(
                            (entry) => {
                              "id": entry.key,
                              ...Map<String, dynamic>.from(entry.value),
                            },
                          )
                          .where((article) => article["category"] == "Trending")
                          .toList();

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: trendingArticles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _buildTrendingCardFromArticle(
                        context,
                        trendingArticles[index],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            //  Contact Expert +  Pest Alerts
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 9, 9, 9),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text(
                      'Contact Expert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpertSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 6, 6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bug_report, color: Colors.white),
                    label: const Text(
                      'Pest Alerts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PestAlertsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //  Card Widget with optional subtitle
  static Widget _buildCard(String title, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xffb0e8b2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
        ],
      ),
    );
  }

  //  Circular farm action (add/view)
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
              backgroundColor: Colors.green.shade200,
              child:
                  icon != null
                      ? Icon(icon, size: 30, color: Colors.black)
                      : image != null
                      ? ClipOval(
                        child: Image.asset(
                          image!,
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

  //  Trending Article Card
  static Widget _buildTrendingCardFromArticle(
    BuildContext context,
    Map<String, dynamic> article,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(article: article),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                article["imageUrl"] ?? '',
                height: 100,
                width: 130,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey[300],
                      height: 100,
                      width: 130,
                      child: const Icon(Icons.broken_image),
                    ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              article["title"] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              (article["content"] ?? '')
                  .toString()
                  .replaceAll('\n', ' ')
                  .substring(0, (article["content"] ?? '').length.clamp(0, 30)),
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  //  Tip box
  Widget _buildTipBox(String tip, {bool isEmpty = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color:
            isEmpty
                ? const Color(0xFFFFF3E0)
                : const Color.fromARGB(255, 15, 37, 17),
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isEmpty
                ? []
                : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEmpty ? Icons.info_outline : Icons.tips_and_updates,
            color: isEmpty ? Colors.deepOrange : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isEmpty
                        ? Colors.deepOrange
                        : const Color.fromARGB(255, 233, 247, 233),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
