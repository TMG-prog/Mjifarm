import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _gardenTypes = [
    'Rooftop',
    'Balcony',
    'Backyard',
    'Windowsill',
    'Community Garden',
  ];

  String? _selectedCategory;
  String? _selectedContainer;
  String? _selectedGarden;
  DateTime? _plantingDate;
  DateTime? _maturityDate;
  final _nameController = TextEditingController();

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

  Future<void> _savePlant() async {
    if (_nameController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedContainer == null ||
        _selectedGarden == null ||
        _plantingDate == null ||
        _maturityDate == null) {
      _showError('Please fill in all fields before saving.');
      return;
    }

    await FirebaseFirestore.instance.collection('plants').add({
      'name': _nameController.text,
      'category': _selectedCategory,
      'container': _selectedContainer,
      'garden': _selectedGarden,
      'plantingDate': _plantingDate!.toIso8601String(),
      'maturityDate': _maturityDate!.toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showSuccess();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Missing Information'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
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
            title: Text('Success'),
            content: Text('Plant saved!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/myplants');
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  ListTile _buildDropdown(
    String title,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        hint: Text('Select'),
        value: selectedValue,
        onChanged: onChanged,
        items:
            items
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
      trailing: Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        backgroundColor: const Color.fromARGB(255, 176, 232, 178),
        title: Text('New Plant'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/myplants');
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 30, color: Colors.black54),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Name'),
              subtitle: TextField(
                controller: _nameController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Add name of crop',
                ),
              ),
              trailing: Icon(Icons.chevron_right),
            ),
            Divider(),
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
            _buildDropdown(
              'Garden Type',
              _gardenTypes,
              _selectedGarden,
              (val) => setState(() => _selectedGarden = val),
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
                SizedBox(width: 10),
                Expanded(
                  child: _buildDateTile(
                    'Maturity Date',
                    _maturityDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            Divider(),
            ElevatedButton(
              onPressed: _savePlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 34, 94, 36),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
