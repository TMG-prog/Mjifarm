import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart'; // Removed as manual picking is no longer allowed
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'plants.dart'; // Assuming this file defines your Plant model if used elsewhere

class NewPlantPage extends StatefulWidget {
  const NewPlantPage({super.key});

  @override
  _NewPlantPageState createState() => _NewPlantPageState();
}

class _NewPlantPageState extends State<NewPlantPage> {
  final _containerTypes = [
    'Sack',
    'Plastic Container',
    'Plastic Bag',
    'Tray',
    'None',
  ];

  String? _selectedCropType;
  String? _selectedContainer;
  String? _selectedGardenId;
  String? _selectedGardenName;

  DateTime? _plantingDate;
  final _nameController = TextEditingController();

  User? _currentUser;
  List<DataSnapshot> _userGardens = [];
  Map<String, int> _cropHarvestDurations =
      {}; // Stores crop type -> harvest days
  Map<String, String> _cropImagesBase64 =
      {}; // New: Stores crop type -> base64 image string

  bool _isLoadingGardens = true;
  bool _isLoadingCropData = true;

  String? _currentCropImageBase64; // Used to display the selected crop's image

  final _newGardenNameController = TextEditingController();
  final _newGardenLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserGardens();
    _fetchCropData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newGardenNameController.dispose();
    _newGardenLocationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCropData() async {
    try {
      final DatabaseReference cropsRef = FirebaseDatabase.instance.ref('crops');
      final DatabaseEvent event = await cropsRef.once();
      final DataSnapshot dataSnapshot = event.snapshot;

      Map<String, int> fetchedDurations = {};
      Map<String, String> fetchedImages = {};

      if (dataSnapshot.value != null && dataSnapshot.value is Map) {
        Map<dynamic, dynamic> cropsMap =
            dataSnapshot.value as Map<dynamic, dynamic>;
        cropsMap.forEach((key, value) {
          if (value is Map) {
            if (value.containsKey('harvestDurationDays')) {
              fetchedDurations[key as String] =
                  value['harvestDurationDays'] as int;
            }
            if (value.containsKey('imageBase64')) {
              fetchedImages[key as String] = value['imageBase64'] as String;
            }
          }
        });
      }

      setState(() {
        _cropHarvestDurations = fetchedDurations;
        _cropImagesBase64 = fetchedImages;
        _isLoadingCropData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCropData = false;
      });
      _showError('Failed to load crop information: $e');
      print('Error fetching crop data from RTDB: $e');
    }
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
      final DatabaseReference gardensRef = FirebaseDatabase.instance.ref(
        'gardens',
      );
      final DatabaseEvent event =
          await gardensRef
              .orderByChild('userID')
              .equalTo(_currentUser!.uid)
              .once();

      final DataSnapshot dataSnapshot = event.snapshot;

      List<DataSnapshot> fetchedGardens = [];
      if (dataSnapshot.value != null && dataSnapshot.value is Map) {
        Map<dynamic, dynamic> gardensMap =
            dataSnapshot.value as Map<dynamic, dynamic>;
        gardensMap.forEach((key, value) {
          fetchedGardens.add(dataSnapshot.child(key));
        });
      }

      setState(() {
        _userGardens = fetchedGardens;
        _isLoadingGardens = false;
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

  Future<void> _selectPlantingDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }

  // Removed _pickImage() method entirely as per user's request

  Future<void> _savePlant() async {
    if (_currentUser == null) {
      _showError('You must be logged in to save a plant.');
      return;
    }

    DateTime? calculatedMaturityDate;
    if (_plantingDate != null && _selectedCropType != null) {
      final int? harvestDays = _cropHarvestDurations[_selectedCropType];
      if (harvestDays != null) {
        calculatedMaturityDate = _plantingDate!.add(
          Duration(days: harvestDays),
        );
      }
    }

    if (_nameController.text.isEmpty ||
        _selectedCropType == null ||
        _selectedContainer == null ||
        _selectedGardenId == null ||
        _plantingDate == null ||
        calculatedMaturityDate == null) {
      _showError(
        'Please fill in all fields and select a valid crop type with planting date.',
      );
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving plant data...')));

      final DatabaseReference plantsRef = FirebaseDatabase.instance
          .ref('gardens')
          .child(_selectedGardenId!)
          .child('plants');

      await plantsRef.push().set({
        'name': _nameController.text,
        'category': _selectedCropType,
        'container': _selectedContainer,
        'gardenName': _selectedGardenName,
        'gardenId': _selectedGardenId,
        'plantingDate': _plantingDate!.toIso8601String(),
        'maturityDate': calculatedMaturityDate.toIso8601String(),
        'userID': _currentUser!.uid,
        'timestamp': ServerValue.timestamp,
        'imageBase64':
            _currentCropImageBase64, // Use the image from the selected crop
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
    if (_newGardenNameController.text.isEmpty ||
        _newGardenLocationController.text.isEmpty) {
      _showError('Please enter both garden name and location.');
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Creating new garden...')));

      await FirebaseDatabase.instance.ref('gardens').push().set({
        'name': _newGardenNameController.text,
        'location': _newGardenLocationController.text,
        'userID': _currentUser!.uid,
        'createdAt': ServerValue.timestamp,
      });

      _newGardenNameController.clear();
      _newGardenLocationController.clear();

      Navigator.of(context).pop();
      await _fetchUserGardens();

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
              onPressed: _createNewGarden,
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
      builder:
          (_) => AlertDialog(
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
      builder:
          (_) => AlertDialog(
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
    bool isLoading = false,
  }) {
    return ListTile(
      title: Text(title),
      trailing:
          isLoading
              ? const CircularProgressIndicator()
              : DropdownButton<String>(
                hint: Text(hintText ?? 'Select'),
                value: selectedValue,
                onChanged: items.isEmpty ? null : onChanged,
                items:
                    items
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
              ),
    );
  }

  ListTile _buildDateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        date == null
            ? 'Select date'
            : DateFormat('yyyy-MM-dd').format(date.toLocal()),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool overallLoading = _isLoadingGardens || _isLoadingCropData;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: const Color.fromARGB(255, 176, 232, 178),
        title: const Text('New Plant'),
        centerTitle: true,
      ),
      body:
          overallLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView(
                  children: [
                    // Image display now uses _currentCropImageBase64, no picking
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _currentCropImageBase64 != null &&
                                  _currentCropImageBase64!.isNotEmpty
                              ? MemoryImage(
                                base64Decode(_currentCropImageBase64!),
                              )
                              : null,
                      child:
                          (_currentCropImageBase64 == null ||
                                  _currentCropImageBase64!.isEmpty)
                              ? const Icon(
                                Icons.grass,
                                size: 30,
                                color: Colors.black54,
                              ) // Generic plant icon
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // Name field (autofilled, but still editable)
                    ListTile(
                      title: const Text('Plant Name'),
                      subtitle: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'e.g., My Special Tomato',
                        ),
                      ),
                      trailing: const Icon(
                        Icons.edit,
                      ), // Changed icon to suggest editability
                    ),
                    const Divider(),

                    // Crop Type Dropdown
                    _buildDropdown(
                      'Crop Type',
                      _cropHarvestDurations.keys.toList(),
                      _selectedCropType,
                      (val) {
                        setState(() {
                          _selectedCropType = val;
                          // Autofill name and set default image when crop type changes
                          if (val != null) {
                            _nameController.text = val; // Autofill name
                            _currentCropImageBase64 =
                                _cropImagesBase64[val]; // Set default image
                          } else {
                            _nameController.clear();
                            _currentCropImageBase64 = null;
                          }
                        });
                      },
                      isLoading: _isLoadingCropData,
                      hintText: 'Select a crop type',
                    ),

                    _buildDropdown(
                      'Container Type',
                      _containerTypes,
                      _selectedContainer,
                      (val) => setState(() => _selectedContainer = val),
                    ),

                    _userGardens.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'You haven\'t created any gardens yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _showCreateGardenDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Garden'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
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
                          _userGardens
                              .map(
                                (snapshot) =>
                                    (snapshot.value as Map)['name'] as String,
                              )
                              .toList(),
                          _selectedGardenName,
                          (val) {
                            setState(() {
                              _selectedGardenName = val;
                              _selectedGardenId =
                                  _userGardens
                                      .firstWhere(
                                        (snapshot) =>
                                            (snapshot.value as Map)['name'] ==
                                            val,
                                      )
                                      .key;
                            });
                          },
                          hintText: 'Select',
                        ),

                    _buildDateTile(
                      'Planting Date',
                      _plantingDate,
                      () => _selectPlantingDate(context),
                    ),

                    if (_plantingDate != null &&
                        _selectedCropType != null &&
                        _cropHarvestDurations.containsKey(_selectedCropType))
                      ListTile(
                        title: const Text('Expected Maturity Date'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(
                            _plantingDate!
                                .add(
                                  Duration(
                                    days:
                                        _cropHarvestDurations[_selectedCropType]!,
                                  ),
                                )
                                .toLocal(),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.info_outline),
                      ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed:
                            (_userGardens.isEmpty ||
                                    _selectedCropType == null ||
                                    _plantingDate == null ||
                                    _nameController.text.isEmpty)
                                ? null
                                : _savePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_userGardens.isEmpty ||
                                      _selectedCropType == null ||
                                      _plantingDate == null ||
                                      _nameController.text.isEmpty)
                                  ? Colors.grey
                                  : const Color.fromARGB(255, 34, 94, 36),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
