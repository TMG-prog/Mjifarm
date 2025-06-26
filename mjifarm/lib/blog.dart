import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mjifarm/article.dart';
import 'package:mjifarm/fprofile.dart';
// Make sure this file exists and is imported

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  // List of predefined categories
  final List<String> categories = [
    "All",
    "Tips",
    "Health",
    "Crops",
    "News",
    "Trending",
  ];

  String selectedCategory = "All"; // The currently selected category

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Articles"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FarmerProfilePage()),
                );
          }),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                String category = categories[index];
                bool isSelected = category == selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Realtime articles stream
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('articles').onValue,
              builder: (context, snapshot) {
                // Show loading spinner while waiting for data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show message if there's no data
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No articles found"));
                }

                // Convert database Map to a List of articles
                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                // Filter articles based on selected category
                final docs =
                    data.entries
                        .map(
                          (entry) => {
                            "id": entry.key,
                            ...Map<String, dynamic>.from(entry.value),
                          },
                        )
                        .where(
                          (doc) =>
                              selectedCategory == "All" ||
                              doc["category"] == selectedCategory,
                        )
                        .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    section("Featured", docs),
                    const SizedBox(height: 16),
                    section("Latest", docs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Section for displaying articles in horizontal scroll
  Widget section(String title, List<Map<String, dynamic>> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal article cards
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return blogCard(docs[index]);
            },
          ),
        ),
      ],
    );
  }

  // Individual article card
  Widget blogCard(Map<String, dynamic> article) {
    {
    final String? imageUrl = article["imageUrl"] as String?;
    ImageProvider? imageProvider;
    Widget errorWidget = Container(
      color: Colors.grey[300],
      height: 100,
      width: 130,
      child: const Icon(Icons.broken_image),
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image/') || imageUrl.length > 500) { // Simple heuristic for Base64 (length check is a guess)
        try {
          // Remove "data:image/jpeg;base64," or similar prefixes if present
          final String base64String = imageUrl.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (e) {
          print("Error decoding base64 image for article: $e");
          imageProvider = null; // Fallback to null, which will show errorWidget
        }
      } else if (Uri.tryParse(imageUrl)?.hasScheme == true && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
        imageProvider = NetworkImage(imageUrl);
      }
    }
    return GestureDetector(
      onTap: () {
        // Navigate to article detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(article: article),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: Column(
          children: [
            // Article image
             ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageProvider != null
                  ? Image(
                      image: imageProvider,
                      height: 100,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => errorWidget, // Use the common error widget
                    )
                  : errorWidget, // Show error widget if no valid imageProvider
            ),

            // Article title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                article["title"] ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
}