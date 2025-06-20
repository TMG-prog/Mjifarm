import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference

class CropInfoManagementContent extends StatefulWidget {
  const CropInfoManagementContent({super.key});

  @override
  State<CropInfoManagementContent> createState() => _CropInfoManagementContentState();
}

class _CropInfoManagementContentState extends State<CropInfoManagementContent> {
  late DatabaseReference _cropInfoRef;
  List<Map<String, dynamic>> _cropInfos = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _commonNameController = TextEditingController();
  TextEditingController _scientificNameController = TextEditingController();
  TextEditingController _plantingGuideController = TextEditingController();
  TextEditingController _imageURLController = TextEditingController();

  Map<String, dynamic>? _currentCrop; // For editing existing crop info

  @override
  void initState() {
    super.initState();
    _cropInfoRef = FirebaseDatabase.instance.ref('crop_info');
    _listenToCropInfo();
  }

  @override
  void dispose() {
    _commonNameController.dispose();
    _scientificNameController.dispose();
    _plantingGuideController.dispose();
    _imageURLController.dispose();
    super.dispose();
  }

  void _listenToCropInfo() {
    _cropInfoRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedCropInfo = [];
        data.forEach((key, value) {
          if (value is Map) {
            fetchedCropInfo.add({'id': key, ...Map<String, dynamic>.from(value)});
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

  void _handleEdit(Map<String, dynamic> crop) {
    setState(() {
      _currentCrop = Map.from(crop); // Create a mutable copy
      _commonNameController.text = _currentCrop!['commonName'] ?? '';
      _scientificNameController.text = _currentCrop!['scientificName'] ?? '';
      _plantingGuideController.text = _currentCrop!['plantingGuide'] ?? '';
      _imageURLController.text = _currentCrop!['imageURL'] ?? '';
    });
  }

  void _handleDelete(String cropId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete crop info $cropId?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _cropInfoRef.child(cropId).remove();
                  _showSnackBar('Crop info $cropId deleted.', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to delete crop info: $e', Colors.red);
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
        if (_currentCrop != null) { // Editing existing
          await _cropInfoRef.child(_currentCrop!['id']).update({
            'commonName': _commonNameController.text,
            'scientificName': _scientificNameController.text,
            'plantingGuide': _plantingGuideController.text,
            'imageURL': _imageURLController.text,
          });
          _showSnackBar('Crop info updated!', Colors.green);
        } else { // Adding new
          await _cropInfoRef.push().set({
            'commonName': _commonNameController.text,
            'scientificName': _scientificNameController.text,
            'plantingGuide': _plantingGuideController.text,
            'imageURL': _imageURLController.text,
          });
          _showSnackBar('New crop info added!', Colors.green);
        }
        _clearForm();
      } catch (e) {
        _showSnackBar('Failed to save crop info: $e', Colors.red);
      }
    }
  }

  void _clearForm() {
    _commonNameController.clear();
    _scientificNameController.clear();
    _plantingGuideController.clear();
    _imageURLController.clear();
    setState(() {
      _currentCrop = null;
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
                            labelText: 'Common Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter common name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _scientificNameController,
                          decoration: InputDecoration(
                            labelText: 'Scientific Name',
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
                          controller: _imageURLController,
                          decoration: InputDecoration(
                            labelText: 'Image URL',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
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
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: const [
                    DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Common Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Scientific Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Planting Guide', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _cropInfos.map((crop) => DataRow(cells: [
                    DataCell(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          crop['imageURL'] ?? 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=No+Image',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 60, height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                        ),
                      ),
                    ),
                    DataCell(Text(crop['commonName'] ?? 'N/A')),
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
