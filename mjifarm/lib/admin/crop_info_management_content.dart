import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert'; // For Base64 encoding/decoding
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Needed for File operations (XFile to File)

class CropInfoManagementContent extends StatefulWidget {
  const CropInfoManagementContent({super.key});

  @override
  State<CropInfoManagementContent> createState() => _CropInfoManagementContentState();
}

class _CropInfoManagementContentState extends State<CropInfoManagementContent> {
  late DatabaseReference _cropsRef;
  List<Map<String, dynamic>> _cropInfos = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _commonNameController = TextEditingController();
  final TextEditingController _scientificNameController = TextEditingController();
  final TextEditingController _plantingGuideController = TextEditingController();
  final TextEditingController _harvestDurationDaysController = TextEditingController();
  final TextEditingController _imageBase64Controller = TextEditingController(); // This will hold the Base64 string

  Map<String, dynamic>? _currentCrop; // For editing existing crop info

  final ImagePicker _picker = ImagePicker(); // ImagePicker instance
  String? _previewImageBase64; // To hold the Base64 for the current preview image

  @override
  void initState() {
    super.initState();
    _cropsRef = FirebaseDatabase.instance.ref('crops');
    _listenToCropInfo();
  }

  @override
  void dispose() {
    _commonNameController.dispose();
    _scientificNameController.dispose();
    _plantingGuideController.dispose();
    _harvestDurationDaysController.dispose();
    _imageBase64Controller.dispose();
    super.dispose();
  }

  void _listenToCropInfo() {
    _cropsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedCropInfo = [];
        data.forEach((key, value) {
          if (value is Map) {
            final Map<String, dynamic> cropData = Map<String, dynamic>.from(value);
            fetchedCropInfo.add({'id': key, ...cropData});
          }
        });
        setState(() {
          _cropInfos = fetchedCropInfo;
          _isLoading = false;
        });
      } else {
        setState(() {
          _cropInfos = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error listening to crop info: $error");
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Error fetching crop info: $error", Colors.red);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), backgroundColor: color),
    );
  }

  // Method to pick an image and convert it to Base64
  Future<void> _pickImageAndConvertToBase64() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _imageBase64Controller.text = base64String; // Update the text field with Base64
          _previewImageBase64 = base64String; // Update the preview image
        });
        _showSnackBar('Image selected and converted to Base64.', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to process image: $e', Colors.red);
        print('Error converting image to Base64: $e');
      }
    }
  }

  void _handleEdit(Map<String, dynamic> crop) {
    setState(() {
      _currentCrop = Map.from(crop);
      _commonNameController.text = _currentCrop!['commonName'] ?? '';
      _scientificNameController.text = _currentCrop!['scientificName'] ?? '';
      _plantingGuideController.text = _currentCrop!['plantingGuide'] ?? '';
      _harvestDurationDaysController.text = (_currentCrop!['harvestDurationDays'] ?? '').toString();
      _imageBase64Controller.text = _currentCrop!['imageBase64'] ?? ''; // Populate Base64 field
      _previewImageBase64 = _currentCrop!['imageBase64'] ?? ''; // Set preview image
    });
  }

  void _handleDelete(String cropId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete crop: $cropId?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _cropsRef.child(cropId).remove();
                  _showSnackBar('Crop $cropId deleted.', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to delete crop: $e', Colors.red);
                } finally {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      try {
        final Map<String, dynamic> cropData = {
          'commonName': _commonNameController.text,
          'scientificName': _scientificNameController.text,
          'plantingGuide': _plantingGuideController.text,
          'harvestDurationDays': int.tryParse(_harvestDurationDaysController.text) ?? 0,
          'imageBase64': _imageBase64Controller.text, // Use the Base64 from the controller
        };

        if (_currentCrop != null) {
          await _cropsRef.child(_currentCrop!['id']).update(cropData);
          _showSnackBar('Crop info updated!', Colors.green);
        } else {
          if (cropData['commonName'] == null || cropData['commonName'].isEmpty) {
            _showSnackBar('Common Name cannot be empty for new crops.', Colors.red);
            return;
          }
          await _cropsRef.child(_commonNameController.text).set(cropData);
          _showSnackBar('New crop info added!', Colors.green);
        }
        _clearForm();
      } catch (e) {
        _showSnackBar('Failed to save crop info: $e', Colors.red);
        print("Save Error: $e");
      }
    }
  }

  void _clearForm() {
    _commonNameController.clear();
    _scientificNameController.clear();
    _plantingGuideController.clear();
    _harvestDurationDaysController.clear();
    _imageBase64Controller.clear();
    setState(() {
      _currentCrop = null;
      _previewImageBase64 = null; // Clear preview image
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crop Information Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentCrop != null ? 'Edit Crop Info' : 'Add New Crop Info',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _commonNameController,
                          decoration: InputDecoration(
                            labelText: 'Common Name (e.g., Tomato)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter common name';
                            }
                            return null;
                          },
                          readOnly: _currentCrop != null,
                          style: _currentCrop != null ? const TextStyle(color: Colors.grey) : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _scientificNameController,
                          decoration: InputDecoration(
                            labelText: 'Scientific Name (e.g., Solanum lycopersicum)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter scientific name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plantingGuideController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Planting Guide',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter planting guide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _harvestDurationDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Harvest Duration (Days)',
                            hintText: 'e.g., 90',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter harvest duration';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24), // Increased spacing
                        // Image selection and preview section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Crop Image',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                              child: (_previewImageBase64 != null && _previewImageBase64!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(_previewImageBase64!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.image, size: 50, color: Colors.grey),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Optional: Show the Base64 string in a disabled TextFormField
                                  TextFormField(
                                    controller: _imageBase64Controller,
                                    maxLines: 2, // Keep it compact
                                    readOnly: true, // Make it read-only as it's filled by the picker
                                    decoration: InputDecoration(
                                      labelText: 'Base64 String (Auto-filled)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_currentCrop != null)
                              TextButton(
                                onPressed: _clearForm,
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _handleSave,
                              icon: Icon(_currentCrop != null ? Icons.save : Icons.add_circle),
                              label: Text(_currentCrop != null ? 'Save Changes' : 'Add New Crop Info'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Existing Crop Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 16.0,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 90,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: const [
                    DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Common Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Harvest Days', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Scientific Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Planting Guide', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _cropInfos.map((crop) => DataRow(cells: [
                    DataCell(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: (crop['imageBase64'] != null && crop['imageBase64'].isNotEmpty)
                            ? Image.memory(
                                base64Decode(crop['imageBase64']),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 60, height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                              )
                            : Container(
                                width: 60, height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                      ),
                    ),
                    DataCell(Text(crop['commonName'] ?? 'N/A')),
                    DataCell(Text((crop['harvestDurationDays'] ?? 'N/A').toString())),
                    DataCell(Text(crop['scientificName'] ?? 'N/A')),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          crop['plantingGuide'] != null && crop['plantingGuide'].length > 100
                              ? '${crop['plantingGuide'].substring(0, 100)}...'
                              : crop['plantingGuide'] ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit Crop Info',
                            onPressed: () => _handleEdit(crop),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Crop Info',
                            onPressed: () => _handleDelete(crop['id']),
                          ),
                        ],
                      ),
                    ),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}