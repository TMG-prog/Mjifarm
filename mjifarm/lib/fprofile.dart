import 'dart:convert';
import 'dart:io'; // For File and Platform checks
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mjifarm/report.dart';

class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({super.key});

  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  late DatabaseReference farmersRef;
  bool _isLoading = true;

  // State variable to track if an image has been uploaded/loaded
  bool _isImageUploaded = false;

  // TextEditingControllers for all form fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _farmingTypeController;
  final TextEditingController _imageBase64Controller =
      TextEditingController(); // Holds the Base64 string

  String?
  _previewImageBase64; // To hold the Base64 for the current preview image
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _farmingTypeController = TextEditingController();

    if (user != null) {
      farmersRef = FirebaseDatabase.instance.ref("farmers/${user!.uid}");
      _listenToProfile(); // Start listening for real-time updates
    } else {
      // Handle case where user is not logged in (should ideally be handled by AuthGate)
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('User not logged in.', Colors.red);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _farmingTypeController.dispose();
    _imageBase64Controller.dispose();
    super.dispose();
  }

  // Real-time listener for profile data
  void _listenToProfile() {
    farmersRef.onValue.listen(
      (event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists &&
            dataSnapshot.value != null &&
            dataSnapshot.value is Map) {
          final Map<dynamic, dynamic> profileData = Map<dynamic, dynamic>.from(
            dataSnapshot.value as Map,
          );

          setState(() {
            _nameController.text =
                profileData['name']?.toString() ?? user?.displayName ?? '';
            _emailController.text =
                profileData['email']?.toString() ?? user?.email ?? '';
            _phoneController.text = profileData['phone']?.toString() ?? '';
            _locationController.text =
                profileData['location']?.toString() ?? '';
            _farmingTypeController.text =
                profileData['farmingType']?.toString() ?? '';

            final String? fetchedImageBase64 = profileData['image']?.toString();
            if (fetchedImageBase64 != null && fetchedImageBase64.isNotEmpty) {
              _previewImageBase64 = fetchedImageBase64;
              _imageBase64Controller.text =
                  fetchedImageBase64; // Keep controller updated for saving
              _isImageUploaded =
                  true; // Set to true if an image is loaded from DB
            } else {
              _previewImageBase64 = null;
              _imageBase64Controller.text = '';
              _isImageUploaded = false; // Reset if no image in DB
            }
            _isLoading = false;
          });
        } else {
          // If no data exists, initialize with Firebase Auth data and mark as not loading
          setState(() {
            _nameController.text = user?.displayName ?? '';
            _emailController.text = user?.email ?? '';
            _phoneController.text = '';
            _locationController.text = '';
            _farmingTypeController.text = '';
            _previewImageBase64 = null;
            _imageBase64Controller.text = '';
            _isImageUploaded = false; // No image, so fields are enabled
            _isLoading = false;
          });
          print(
            "No existing profile data found for ${user?.uid}. Initializing empty fields.",
          );
        }
      },
      onError: (error) {
        print("Error listening to profile info: $error");
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Error fetching profile info: $error", Colors.red);
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please correct the errors in the form.', Colors.orange);
      return;
    }

    if (user == null) {
      _showSnackBar('User not logged in.', Colors.red);
      return;
    }

    // Capture current values from controllers
    final String currentName = _nameController.text.trim();
    final String currentEmail = _emailController.text.trim();
    final String currentPhone = _phoneController.text.trim();
    final String currentLocation = _locationController.text.trim();
    final String currentFarmingType = _farmingTypeController.text.trim();
    final String currentImageBase64 = _imageBase64Controller.text.trim();

    try {
      if (user!.displayName != currentName) {
        await user!.updateDisplayName(currentName);
      }

      await farmersRef.update({
        // Use .set() if you want to overwrite, .update() if you want to merge
        "name": currentName,
        "email": currentEmail, // Store email here as well
        'phone': currentPhone,
        'location': currentLocation,
        'farmingType': currentFarmingType,
        'image': currentImageBase64, // Correctly store the Base64 string
      });

      _showSnackBar('✅ Profile updated successfully!', Colors.green);
    } catch (e) {
      print("Error updating profile: $e");
      _showSnackBar('⚠️ Failed to update profile: $e', Colors.red);
    }
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
          _imageBase64Controller.text = base64String;
          _previewImageBase64 = base64String;
          _isImageUploaded = true;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Farmer Profile'),
          backgroundColor: Colors.green.shade700,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                ),
                              )
                              : const Icon(
                                Icons
                                    .person, // Changed from Icons.image to person for profile picture
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

                          TextFormField(
                            controller: _imageBase64Controller,
                            maxLines: 2, // Keep it compact
                            readOnly:
                                true, // Make it read-only as it's filled by the picker
                            decoration: InputDecoration(
                              labelText: 'Profile Image (Base64)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                            ), // Smaller text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Spacing below image section

                TextFormField(
                  controller: _nameController,
                  readOnly:
                      _isImageUploaded, // This line disables if image uploaded
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (val) =>
                          val == null || !val.contains('@')
                              ? 'Enter valid email'
                              : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator:
                      (val) =>
                          val == null || val.length < 10
                              ? 'Enter valid phone number (min 10 digits)'
                              : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Enter location' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _farmingTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Farming Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Enter farming type'
                              : null,
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity, // Make button fill width
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white, // Text color
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Spacing below button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white, // Text color
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Generate Report",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
