import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:convert'; // For Base64 decoding

import 'plantdetails.dart'; 

class MyPlantsPage extends StatefulWidget {
  const MyPlantsPage({super.key});

  @override
  State<MyPlantsPage> createState() => _MyPlantsPageState();
}

class _MyPlantsPageState extends State<MyPlantsPage> {
  User? _currentUser;
  bool _isLoading = true; // To track initial loading of gardens
  List<DataSnapshot> _userGardens = []; // To hold DataSnapshots of user's gardens
  String _searchQuery = ''; // For the search functionality

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Handle case where user is not logged in, perhaps navigate to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to view your plants.')),
        );
        // Consider navigating to a login page or showing an empty state
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      _fetchUserGardens();
    }
  }

  // Fetches gardens belonging to the current user from Realtime Database
  Future<void> _fetchUserGardens() async {
    if (_currentUser == null) return;

    try {
      final DatabaseReference gardensRef = FirebaseDatabase.instance.ref('gardens');
      final DatabaseEvent event = await gardensRef
          .orderByChild('userID')
          .equalTo(_currentUser!.uid)
          .once(); // Use once() for a single fetch

      final DataSnapshot dataSnapshot = event.snapshot;

      List<DataSnapshot> fetchedGardens = [];
      if (dataSnapshot.value != null && dataSnapshot.value is Map) {
        Map<dynamic, dynamic> gardensMap = dataSnapshot.value as Map<dynamic, dynamic>;
        gardensMap.forEach((key, value) {
          // Reconstruct DataSnapshot for each child garden
          fetchedGardens.add(dataSnapshot.child(key));
        });
      }

      setState(() {
        _userGardens = fetchedGardens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching gardens from RTDB: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading gardens: $e')),
      );
    }
  }

  // --- Helper functions for plant details (same as before) ---
  String _daysUntilHarvestText(Map<dynamic, dynamic> plant) {
    try {
      final maturityDate = DateTime.parse(plant['maturityDate']);
      final now = DateTime.now();
      final daysLeft = maturityDate.difference(now).inDays;
      return daysLeft >= 0 ? '$daysLeft days until Harvest' : 'Ready to harvest!';
    } catch (e) {
      return 'Unknown harvest date';
    }
  }

  String _determineGrowthStatus(Map<dynamic, dynamic> plant) {
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

  int _calculateGrowthPercentage(Map<dynamic, dynamic> plant) {
    try {
      final now = DateTime.now();
      final planting = DateTime.parse(plant['plantingDate']);
      final maturity = DateTime.parse(plant['maturityDate']);
      final totalDays = maturity.difference(planting).inDays;
      final daysPassed = now.difference(planting).inDays;

      final percent = ((daysPassed / totalDays) * 100).clamp(0, 100);
      return percent.floor();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [BackButton(), Icon(Icons.more_vert)],
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Display loading indicator or gardens
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userGardens.isEmpty
                      ? const Center(
                          child: Text(
                            'No gardens found. Create a garden first!',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _userGardens.length,
                            itemBuilder: (context, index) {
                              final gardenSnapshot = _userGardens[index];
                              final gardenId = gardenSnapshot.key;
                              final gardenData = gardenSnapshot.value as Map<dynamic, dynamic>;
                              final gardenName = gardenData['name'] ?? 'Unnamed Garden';

                              // StreamBuilder for plants within each garden
                              return StreamBuilder<DatabaseEvent>(
                                stream: FirebaseDatabase.instance
                                    .ref('gardens')
                                    .child(gardenId!)
                                    .child('plants')
                                    .orderByChild('timestamp') // Order plants by timestamp
                                    .onValue, // Use onValue for real-time updates
                                builder: (context, plantEventSnapshot) {
                                  if (plantEventSnapshot.connectionState == ConnectionState.waiting) {
                                    return ExpansionTile(
                                      title: Text('$gardenName (Loading Plants...)'),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      ],
                                    );
                                  }

                                  if (plantEventSnapshot.hasError) {
                                    return ExpansionTile(
                                      title: Text('$gardenName (Error Loading Plants)'),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text('Error: ${plantEventSnapshot.error}'),
                                        ),
                                      ],
                                    );
                                  }

                                  final plantsMap = plantEventSnapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                                  List<Map<dynamic, dynamic>> plants = [];
                                  if (plantsMap != null) {
                                    plantsMap.forEach((key, value) {
                                      plants.add(value as Map<dynamic, dynamic>);
                                    });
                                  }

                                  // Apply search filter
                                  final filteredPlants = plants.where((plant) {
                                    final plantName = (plant['name'] as String? ?? '').toLowerCase();
                                    return plantName.contains(_searchQuery);
                                  }).toList();

                                  return ExpansionTile(
                                    title: Text('$gardenName (${filteredPlants.length} Plants)'),
                                    children: filteredPlants.isEmpty
                                        ? const [
                                            Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text('No plants in this garden or matching search.'),
                                            ),
                                          ]
                                        : filteredPlants.map((plant) {
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => PlantDetailsPage(
                                                      name: plant['name'] ?? 'Unnamed Plant',                                                     
                                                      imagePath: plant['imageBase64'] != null
                                                          ? 'data:image/jpeg;base64,${plant['imageBase64']}'
                                                          : 'assets/plant.png', // Fallback for no image or URL
                                                      growthStatus: _determineGrowthStatus(plant),
                                                      growthPercentage: _calculateGrowthPercentage(plant),
                                                      harvestDate: plant['maturityDate'] ?? 'Unknown',                                                    
                                                      gardenName: plant['gardenName'],
                                                      container: plant['container'],
                                                      category: plant['category'],
                                                      plantingDate: plant['plantingDate'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.green.shade100,
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Display image from Base64 or fallback
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(30),
                                                      child: plant['imageBase64'] != null
                                                          ? Image.memory(
                                                              base64Decode(plant['imageBase64']),
                                                              width: 60,
                                                              height: 60,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Image.asset(
                                                                    'assets/plant.png',
                                                                    width: 60,
                                                                    height: 60,
                                                                    fit: BoxFit.cover);
                                                              },
                                                            )
                                                          : Image.asset(
                                                              'assets/plant.png',
                                                              width: 60,
                                                              height: 60,
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            plant['name'] ?? 'Unnamed Plant',
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            _daysUntilHarvestText(plant),
                                                            style: const TextStyle(
                                                              color: Colors.black54,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
          Navigator.pushNamed(
            context,
            '/newplant', // This route should be defined in your main.dart
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
