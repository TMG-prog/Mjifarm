import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import 'plants.dart'; 

class NewPlantPage extends StatefulWidget {
  @override
  _NewPlantPageState createState() => _NewPlantPageState();
}

class _NewPlantPageState extends State<NewPlantPage> {
  final _categories = [
    'Vegetable',
    'Fruit',
    'Herb',
    'Legume',
    'Tree',
    'Cereal',
  ];
  final _containerTypes = [
    'Sack',
    'Plastic Container',
    'Plastic Bag',
    'Tray',
    'None',
  ];

  String? _selectedCategory;
  String? _selectedContainer;
  String? _selectedGardenId;
  String? _selectedGardenName;

  DateTime? _plantingDate;
  DateTime? _maturityDate;
  final _nameController = TextEditingController();

  User? _currentUser;
  List<DataSnapshot> _userGardens = [];

  bool _isLoadingGardens = true;

  String? _pickedImageBase64;

  // New TextEditingControllers for the garden dialog
  final _newGardenNameController = TextEditingController();
  final _newGardenLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserGardens();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newGardenNameController.dispose();
    _newGardenLocationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserGardens() async {
    if (_currentUser == null) {
      setState(() {
        _isLoadingGardens = false;
      });
      _showError('You must be logged in to add a plant.');
      return;
    }

    try {
      final DatabaseReference gardensRef = FirebaseDatabase.instance.ref('gardens');
      final DatabaseEvent event = await gardensRef
          .orderByChild('userID')
          .equalTo(_currentUser!.uid)
          .once();

      final DataSnapshot dataSnapshot = event.snapshot;

      List<DataSnapshot> fetchedGardens = [];
      if (dataSnapshot.value != null && dataSnapshot.value is Map) {
        Map<dynamic, dynamic> gardensMap = dataSnapshot.value as Map<dynamic, dynamic>;
        gardensMap.forEach((key, value) {
          fetchedGardens.add(dataSnapshot.child(key));
        });
      }

      setState(() {
        _userGardens = fetchedGardens;
        _isLoadingGardens = false;
        // If there's only one garden, pre-select it
        if (_userGardens.length == 1) {
          final gardenData = _userGardens.first.value as Map;
          _selectedGardenName = gardenData['name'] as String;
          _selectedGardenId = _userGardens.first.key;
        } else if (_userGardens.isEmpty) {
          _selectedGardenName = null;
          _selectedGardenId = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingGardens = false;
      });
      _showError('Failed to load your gardens: $e');
      print('Error fetching gardens from RTDB: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPlantingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPlantingDate) {
          _plantingDate = picked;
        } else {
          _maturityDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      try {
        List<int> imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImageBase64 = base64Encode(imageBytes);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected and converted.')),
        );
      } catch (e) {
        _showError('Failed to process image: $e');
        print('Error converting image to Base64: $e');
      }
    }
  }

  Future<void> _savePlant() async {
    if (_currentUser == null) {
      _showError('You must be logged in to save a plant.');
      return;
    }

    if (_nameController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedContainer == null ||
        _selectedGardenId == null ||
        _plantingDate == null ||
        _maturityDate == null) {
      _showError('Please fill in all fields before saving.');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving plant data...')),
      );

      final DatabaseReference plantsRef = FirebaseDatabase.instance
          .ref('gardens')
          .child(_selectedGardenId!)
          .child('plants');

      await plantsRef.push().set({
        'name': _nameController.text,
        'category': _selectedCategory,
        'container': _selectedContainer,
        'gardenName': _selectedGardenName,
        'gardenId': _selectedGardenId,
        'plantingDate': _plantingDate!.toIso8601String(),
        'maturityDate': _maturityDate!.toIso8601String(),
        'userID': _currentUser!.uid,
        'timestamp': ServerValue.timestamp,
        'imageBase64': _pickedImageBase64,
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccess();
    } catch (e) {
      _showError('Failed to save plant: $e');
      print('Error saving plant data to RTDB: $e');
    }
  }

  Future<void> _createNewGarden() async {
    if (_currentUser == null) {
      _showError('You must be logged in to create a garden.');
      return;
    }
    if (_newGardenNameController.text.isEmpty || _newGardenLocationController.text.isEmpty) {
      _showError('Please enter both garden name and location.');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating new garden...')),
      );

      await FirebaseDatabase.instance.ref('gardens').push().set({
        'name': _newGardenNameController.text,
        'location': _newGardenLocationController.text,
        'userID': _currentUser!.uid,
        'createdAt': ServerValue.timestamp,
      });

      _newGardenNameController.clear(); // Clear text fields after saving
      _newGardenLocationController.clear();

      Navigator.of(context).pop(); // Dismiss the dialog
      await _fetchUserGardens(); // Re-fetch gardens to update the dropdown

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Garden created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Failed to create garden: $e');
      print('Error creating garden in RTDB: $e');
    }
  }

  void _showCreateGardenDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Garden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newGardenNameController,
                decoration: const InputDecoration(labelText: 'Garden Name'),
              ),
              TextField(
                controller: _newGardenLocationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _newGardenNameController.clear();
                _newGardenLocationController.clear();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: _createNewGarden, // Call the new create function
              child: const Text('Save Garden'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Plant saved!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/myplants');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  ListTile _buildDropdown(
    String title,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged, {
    String? hintText,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        hint: Text(hintText ?? 'Select'),
        value: selectedValue,
        onChanged: items.isEmpty ? null : onChanged,
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
      ),
    );
  }

  ListTile _buildDateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        date == null ? 'Select date' : '${date.toLocal()}'.split(' ')[0],
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: const Color.fromARGB(255, 176, 232, 178),
        title: const Text('New Plant'),
        centerTitle: true,
      ),
      body: _isLoadingGardens
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _pickedImageBase64 != null
                          ? MemoryImage(base64Decode(_pickedImageBase64!))
                          : null,
                      child: _pickedImageBase64 == null
                          ? const Icon(Icons.camera_alt, size: 30, color: Colors.black54)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Name'),
                    subtitle: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Add name of crop',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const Divider(),
                  _buildDropdown(
                    'Category',
                    _categories,
                    _selectedCategory,
                    (val) => setState(() => _selectedCategory = val),
                  ),
                  _buildDropdown(
                    'Container Type',
                    _containerTypes,
                    _selectedContainer,
                    (val) => setState(() => _selectedContainer = val),
                  ),
                  _userGardens.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              const Text(
                                'You haven\'t created any gardens yet.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _showCreateGardenDialog, // CALLS THE DIALOG HERE
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Garden'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildDropdown(
                          'Garden',
                          _userGardens.map((snapshot) => (snapshot.value as Map)['name'] as String).toList(),
                          _selectedGardenName,
                          (val) {
                            setState(() {
                              _selectedGardenName = val;
                              _selectedGardenId = _userGardens
                                  .firstWhere((snapshot) => (snapshot.value as Map)['name'] == val)
                                  .key;
                            });
                          },
                          hintText: 'Select',
                        ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile(
                          'Planting Date',
                          _plantingDate,
                          () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateTile(
                          'Maturity Date',
                          _maturityDate,
                          () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _userGardens.isEmpty ? null : _savePlant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userGardens.isEmpty ? Colors.grey : const Color.fromARGB(255, 34, 94, 36),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
