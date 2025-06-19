import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final List<String> categories = [
    "All",
    "Tips",
    "Health",
    "Crops",
    "News",
    "Trending",
  ];
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Articles"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Category Chips
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

          // Blog Articles from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  selectedCategory == "All"
                      ? FirebaseFirestore.instance
                          .collection('articles')
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('articles')
                          .where('category', isEqualTo: selectedCategory)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No articles found"));
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

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

  Widget section(String title, List<DocumentSnapshot> docs) {
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
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              Map<String, dynamic> article =
                  docs[index].data() as Map<String, dynamic>;
              return blogCard(article);
            },
          ),
        ),
      ],
    );
  }

  Widget blogCard(Map<String, dynamic> article) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              article["imageUrl"] ?? '',
              height: 100,
              width: 140,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 100,
                    width: 140,
                    color: Colors.grey,
                    child: const Icon(Icons.broken_image),
                  ),
            ),
          ),
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
    );
  }
}
