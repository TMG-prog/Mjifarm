import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article['title'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 4, 28, 5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
            isWide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          article['imageUrl'] ?? '',
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                height: 300,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Text Section
                    Expanded(flex: 2, child: _buildTextContent(theme)),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        article['imageUrl'] ?? '',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              height: 220,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextContent(theme),
                  ],
                ),
      ),
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          article['title'] ?? '',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),

        const SizedBox(height: 10),

        // Category chip
        if (article['category'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              article['category'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Content
        Text(
          article['content'] ?? 'No content available',
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }
}
