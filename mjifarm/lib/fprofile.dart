import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FarmerProfilePage extends StatefulWidget {
  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  String? uid;
  String name = '';
  String email = '';
  String phone = '';
  String location = '';
  String farmingType = '';
  String? photoUrl;

  File? _selectedImage;

  /*@override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _loadProfileData();
  }*/

  Future<void> _loadProfileData() async {
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('farmers').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? '';
          email = data['email'] ?? '';
          phone = data['phone'] ?? '';
          location = data['location'] ?? '';
          farmingType = data['farmingType'] ?? '';
          photoUrl = data['photoUrl'];
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'farmingType': farmingType,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Profile updated')));
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Failed to update profile')));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final file = File(picked.path);
      setState(() => _selectedImage = file);

      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() => photoUrl = url);

      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        'photoUrl': url,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Profile picture updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Profile'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (photoUrl != null
                                  ? NetworkImage(photoUrl!) as ImageProvider
                                  : AssetImage('assets/default_avatar.png')),
                      child:
                          photoUrl == null && _selectedImage == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.grey[700],
                              )
                              : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(labelText: 'Name'),
                  onChanged: (val) => name = val,
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(labelText: 'Email'),
                  onChanged: (val) => email = val,
                  validator:
                      (val) =>
                          val == null || !val.contains('@')
                              ? 'Enter valid email'
                              : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  initialValue: phone,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  onChanged: (val) => phone = val,
                  validator:
                      (val) =>
                          val == null || val.length < 10
                              ? 'Enter valid phone'
                              : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  initialValue: location,
                  decoration: InputDecoration(labelText: 'Location'),
                  onChanged: (val) => location = val,
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Enter location' : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  initialValue: farmingType,
                  decoration: InputDecoration(labelText: 'Farming Type'),
                  onChanged: (val) => farmingType = val,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Enter farming type'
                              : null,
                ),
                SizedBox(height: 25),

                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
