import 'package:flutter/material.dart';
import 'dart:convert'; // Required for base64Decode

class ArticleDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailPage({super.key, required this.article});

  // Helper function to determine the correct ImageProvider
  ImageProvider? _getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null; // No image URL provided
    }

    // Attempt to parse as Base64 first
    if (imageUrl.startsWith('data:image/') || imageUrl.length > 500) { // Heuristic: Starts with data URI or is very long
      try {
        final String base64String = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print("Error decoding base64 image for ArticleDetailPage: $e");
        return null; // Decoding failed
      }
    }
    // Otherwise, assume it's a network URL
    else if (Uri.tryParse(imageUrl)?.hasScheme == true && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return NetworkImage(imageUrl);
    }

    return null; // Fallback if no valid type is detected
  }

  // Define a common error/placeholder image widget
  Widget _buildErrorPlaceholder(double height, {double? width}) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    final String? articleImageUrl = article['imageUrl'] as String?;
    final ImageProvider? imageProvider = _getImageProvider(articleImageUrl);

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
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section for wide screen
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageProvider != null
                          ? Image(
                              image: imageProvider, // Use the determined ImageProvider
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildErrorPlaceholder(300, width: double.infinity),
                            )
                          : _buildErrorPlaceholder(300, width: double.infinity), // Fallback if no provider
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text Section for wide screen
                  Expanded(flex: 2, child: _buildTextContent(theme)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section for narrow screen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageProvider != null
                        ? Image(
                            image: imageProvider, // Use the determined ImageProvider
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildErrorPlaceholder(220, width: double.infinity),
                          )
                        : _buildErrorPlaceholder(220, width: double.infinity), // Fallback if no provider
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