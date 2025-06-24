// contact_experts.dart
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class ContactExpertPage extends StatelessWidget {
  const ContactExpertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 60, 137, 64),
          title: Text(
            "Agricultural Experts",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search experts or expertise...",
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: "All Experts"),
                    Tab(text: "Online Now"),
                    Tab(text: "Verified"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildExpertList(context),
            _buildExpertList(context), // You can filter online experts here
            _buildExpertList(context), // You can filter verified experts here
          ],
        ),
      ),
    );
  }

  Widget _buildExpertList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildExpertCard(
          context,
          name: "Dr. Mary Muthoni",
          location: "Kiambu",
          experience: "15 years experience",
          rating: 4.8,
          reviews: 127,
          tags: ["Crop Diseases", "Organic Farming"],
          responseTime: "Usually responds in 15 mins",
          imageUrl: "https://i.pravatar.cc/100?img=47",
          online: true,
        ),
        const SizedBox(height: 20),
        _buildExpertCard(
          context,
          name: "Moses Omondi",
          location: "Nairobi",
          experience: "12 years experience",
          rating: 4.9,
          reviews: 203,
          tags: ["Irrigation Systems", "Water Management"],
          responseTime: "Usually responds in 1 hour",
          imageUrl: "https://i.pravatar.cc/100?img=60",
          online: false,
        ),
      ],
    );
  }

  Widget _buildExpertCard(
    BuildContext context, {
    required String name,
    required String location,
    required String experience,
    required double rating,
    required int reviews,
    required List<String> tags,
    required String responseTime,
    required String imageUrl,
    bool online = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 3, color: Colors.grey.shade200)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  if (online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified,
                          color: const Color.fromARGB(255, 3, 66, 18),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: const Color.fromARGB(255, 16, 16, 16),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "$rating ($reviews reviews)",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "$location • $experience",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: const Color.fromARGB(255, 252, 252, 252),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),

          // Response time
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                responseTime,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Start Chat Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Handle chat navigation
              },
              icon: Icon(Icons.chat_bubble_outline),
              label: Text("Start Chat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 104, 207, 110),
                foregroundColor: const Color.fromARGB(255, 10, 10, 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
