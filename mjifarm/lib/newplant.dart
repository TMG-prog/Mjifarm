import 'package:flutter/material.dart';

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
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(radius: 50, backgroundColor: Colors.grey[300]),
                  Icon(Icons.camera_alt, size: 30, color: Colors.black54),
                ],
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
            ListTile(
              title: Text('Category'),
              trailing: DropdownButton<String>(
                hint: Text('Select'),
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items:
                    _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Container Type'),
              trailing: DropdownButton<String>(
                hint: Text('Select'),
                value: _selectedContainer,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedContainer = newValue;
                  });
                },
                items:
                    _containerTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Garden Type'),
              trailing: DropdownButton<String>(
                hint: Text('Select'),
                value: _selectedGarden,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGarden = newValue;
                  });
                },
                items:
                    _gardenTypes.map((String garden) {
                      return DropdownMenuItem<String>(
                        value: garden,
                        child: Text(garden),
                      );
                    }).toList(),
              ),
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('Planting Date'),
                    subtitle: Text(
                      _plantingDate == null
                          ? 'Select date'
                          : '${_plantingDate!.toLocal()}'.split(' ')[0],
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: 10), // spacing between the two
                Expanded(
                  child: ListTile(
                    title: Text('Maturity Date'),
                    subtitle: Text(
                      _maturityDate == null
                          ? 'Select date'
                          : '${_maturityDate!.toLocal()}'.split(' ')[0],
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            Divider(),
            Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty ||
                      _selectedCategory == null ||
                      _selectedContainer == null ||
                      _selectedGarden == null ||
                      _plantingDate == null ||
                      _maturityDate == null) {
                    // Show error popup
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Missing Information'),
                          content: Text(
                            'Please fill in all fields before saving.',
                          ),
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Showing confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Success'),
                          content: Text('Plant saved successfully!'),
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/home',
                                ); // Redirect
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all<Size>(
                    Size(double.infinity, 50),
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green.shade700;
                    }
                    return const Color.fromARGB(255, 34, 94, 36);
                  }),
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                ),
                child: Text('Save', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
