import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'plantdetails.dart';

class MyPlantsPage extends StatefulWidget {
  const MyPlantsPage({super.key});

  @override
  State<MyPlantsPage> createState() => _MyPlantsPageState();
}

class _MyPlantsPageState extends State<MyPlantsPage> {
  User? _currentUser;
  bool _isLoading = true;
  List<DataSnapshot> _userGardens = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to view your plants.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      _fetchUserGardens();
    }
  }

  Future<void> _fetchUserGardens() async {
    if (_currentUser == null) return;
    try {
      final gardensRef = FirebaseDatabase.instance.ref('gardens');
      final event =
          await gardensRef
              .orderByChild('userID')
              .equalTo(_currentUser!.uid)
              .once();
      final dataSnapshot = event.snapshot;

      List<DataSnapshot> fetchedGardens = [];
      if (dataSnapshot.value != null && dataSnapshot.value is Map) {
        final gardensMap = dataSnapshot.value as Map;
        gardensMap.forEach((key, _) {
          fetchedGardens.add(dataSnapshot.child(key));
        });
      }

      setState(() {
        _userGardens = fetchedGardens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading gardens: $e')));
    }
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    String gardenId,
    String plantKey,
    String plantName,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete "$plantName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deletePlant(gardenId, plantKey, plantName);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deletePlant(
    String gardenId,
    String plantKey,
    String plantName,
  ) async {
    try {
      final plantRef = FirebaseDatabase.instance
          .ref('gardens')
          .child(gardenId)
          .child('plants')
          .child(plantKey);
      await plantRef.remove();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$plantName" deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete plant: $e')));
    }
  }

  String _daysUntilHarvestText(Map plant) {
    try {
      final maturityDate = DateTime.parse(plant['maturityDate']);
      final now = DateTime.now();
      final daysLeft = maturityDate.difference(now).inDays;
      return daysLeft >= 0
          ? '$daysLeft days until Harvest'
          : 'Ready to harvest!';
    } catch (_) {
      return 'Unknown harvest date';
    }
  }

  String _determineGrowthStatus(Map plant) {
    try {
      final now = DateTime.now();
      final planting = DateTime.parse(plant['plantingDate']);
      final maturity = DateTime.parse(plant['maturityDate']);
      final totalDays = maturity.difference(planting).inDays;
      final daysPassed = now.difference(planting).inDays;
      if (daysPassed <= 0) return 'Just Planted';
      if (daysPassed >= totalDays) return 'Ready';
      final percent = (daysPassed / totalDays) * 100;
      if (percent < 30) return 'Growing';
      if (percent < 80) return 'Maturing';
      return 'Almost Ready';
    } catch (_) {
      return 'Unknown';
    }
  }

  int _calculateGrowthPercentage(Map plant) {
    try {
      final now = DateTime.now();
      final planting = DateTime.parse(plant['plantingDate']);
      final maturity = DateTime.parse(plant['maturityDate']);
      final totalDays = maturity.difference(planting).inDays;
      final daysPassed = now.difference(planting).inDays;
      return ((daysPassed / totalDays) * 100).clamp(0, 100).floor();
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [BackButton(), Icon(Icons.more_vert)],
              ),
              const SizedBox(height: 10),
              const Text(
                'My Plants',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search a plant',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.green[700]),
                  ),
                  onChanged:
                      (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userGardens.isEmpty
                  ? const Center(
                    child: Text('No gardens found. Create a garden first!'),
                  )
                  : Expanded(
                    child: ListView.builder(
                      itemCount: _userGardens.length,
                      itemBuilder: (context, index) {
                        final gardenSnapshot = _userGardens[index];
                        final gardenId = gardenSnapshot.key!;
                        final gardenName =
                            (gardenSnapshot.value as Map)['name'] ??
                            'Unnamed Garden';

                        return StreamBuilder<DatabaseEvent>(
                          stream:
                              FirebaseDatabase.instance
                                  .ref('gardens/$gardenId/plants')
                                  .onValue,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ExpansionTile(
                                title: Text(gardenName),
                                children: [CircularProgressIndicator()],
                              );
                            }

                            final plantsMap =
                                snapshot.data?.snapshot.value
                                    as Map<dynamic, dynamic>?;
                            final List<Map<String, dynamic>> plants = [];

                            if (plantsMap != null) {
                              plantsMap.forEach((key, value) {
                                final plant = Map<String, dynamic>.from(value);
                                plant['key'] =
                                    key; // Store the key for deletion
                                plants.add(plant);
                              });
                            }

                            final filtered =
                                plants
                                    .where(
                                      (p) => (p['name'] ?? '')
                                          .toString()
                                          .toLowerCase()
                                          .contains(_searchQuery),
                                    )
                                    .toList();

                            return ExpansionTile(
                              title: Text(
                                '$gardenName (${filtered.length} plants)',
                              ),
                              children:
                                  filtered.isEmpty
                                      ? [
                                        const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text('No plants found.'),
                                        ),
                                      ]
                                      : filtered.map((plant) {
                                        return ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            child:
                                                plant['imageBase64'] != null
                                                    ? Image.memory(
                                                      base64Decode(
                                                        plant['imageBase64'],
                                                      ),
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : Image.asset(
                                                      'assets/plant.png',
                                                      width: 60,
                                                      height: 60,
                                                    ),
                                          ),
                                          title: Text(
                                            plant['name'] ?? 'Unnamed Plant',
                                          ),
                                          subtitle: Text(
                                            _daysUntilHarvestText(plant),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _showDeleteConfirmationDialog(
                                                context,
                                                gardenId,
                                                plant['key'],
                                                plant['name'] ?? '',
                                              );
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => PlantDetailsPage(
                                                      name:
                                                          plant['name'] ??
                                                          'Unnamed Plant',
                                                      imagePath:
                                                          plant['imageBase64'] !=
                                                                  null
                                                              ? 'data:image/jpeg;base64,${plant['imageBase64']}'
                                                              : 'assets/plant.png',
                                                      growthStatus:
                                                          _determineGrowthStatus(
                                                            plant,
                                                          ),
                                                      growthPercentage:
                                                          _calculateGrowthPercentage(
                                                            plant,
                                                          ),
                                                      harvestDate:
                                                          plant['maturityDate'] ??
                                                          'Unknown',
                                                      gardenName:
                                                          plant['gardenName'],
                                                      container:
                                                          plant['container'],
                                                      category:
                                                          plant['category'],
                                                      plantingDate:
                                                          plant['plantingDate'],
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, '/newplant');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
