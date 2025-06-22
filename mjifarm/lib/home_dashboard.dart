import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:mjifarm/pests.dart';

import 'article.dart';
import 'newplant.dart';
import 'plants.dart';
import 'weather.dart';
import 'farmer_features/expert_selection.dart';

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 100),
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

            // Cards
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

            // Tip of the Day
            FutureBuilder<DatabaseEvent>(
              future: FirebaseDatabase.instance.ref('tips/$todayDate').once(),
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
                }

                final tip = snapshot.data?.snapshot.value?.toString();

                if (tip == null || tip.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.deepOrange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No tip available for today.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 15, 37, 17),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
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
                      const Icon(
                        Icons.tips_and_updates,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 233, 247, 233),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

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

            // 📞 Contact Expert Button at Bottom
            const SizedBox(height: 30),

            // 📞 Contact Expert + Pest Alerts Buttons at Bottom
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
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
                      backgroundColor: Colors.red[600],
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
                      // TODO: Navigate to Pest Alerts page

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PestAlertPage()),
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

  static Widget _buildCard(String title) {
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
}
