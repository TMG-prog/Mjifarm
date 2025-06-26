import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the expert's UID
import 'package:intl/intl.dart'; // For formatting date if needed for articles
import 'dart:convert'; // For Base64 encoding/decoding
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Needed for File operations (XFile to File)

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageBase64Controller = TextEditingController();

  String? _selectedCategory;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  String? _previewImageBase64;

  final List<String> _articleCategories = [
    'Trending',
    'Crops',
    'News',
    'Pests',
    'Diseases',
    'Techniques',
    'Soil',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageBase64Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndConvertToBase64() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _imageBase64Controller.text =
              base64String; // Update the text field with Base64
          _previewImageBase64 = base64String; // Update the preview image
        });
        _showSnackBar('Image selected and converted to Base64.', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to process image: $e', Colors.red);
        print('Error converting image to Base64: $e');
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _publishArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in. Cannot publish article.'),
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      try {
        final DatabaseReference articlesRef = FirebaseDatabase.instance.ref(
          'articles',
        );

        final newArticleKey = articlesRef.push().key; // Generate a unique key

        await articlesRef.child(newArticleKey!).set({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'imageUrl': _imageBase64Controller.text,
          'category': _selectedCategory ?? 'General Farming Tips',
          'expertId': user.uid,
          'expertName': user.displayName ?? user.email ?? 'Expert',
          'timestamp': ServerValue.timestamp,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article published successfully!')),
          );
          Navigator.of(context).pop(); // Go back to the dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to publish article: $e')),
          );
        }
        print("Error publishing article: $e");
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Article'),
        backgroundColor: Colors.green.shade500,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Article Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Article Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Article Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.text_snippet),
                ),
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content for the article';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // Increased spacing
              // Image selection and preview section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Article Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child:
                        (_previewImageBase64 != null &&
                                _previewImageBase64!.isNotEmpty)
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(_previewImageBase64!),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImageAndConvertToBase64,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Optional: Show the Base64 string in a disabled TextFormField
                        TextFormField(
                          controller: _imageBase64Controller,
                          maxLines: 2, // Keep it compact
                          readOnly:
                              true, // Make it read-only as it's filled by the picker
                          decoration: InputDecoration(
                            labelText: 'Base64 String (Auto-filled)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          style: const TextStyle(fontSize: 12), // Smaller text
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                hint: const Text('Select a category'),
                items:
                    _articleCategories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _publishArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.send),
                  label: Text(_isSaving ? 'Publishing...' : 'Publish Article'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
