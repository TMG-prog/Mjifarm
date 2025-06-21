import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart'; 

class ExpertSelectionScreen extends StatefulWidget {
  const ExpertSelectionScreen({super.key});

  @override
  State<ExpertSelectionScreen> createState() => _ExpertSelectionScreenState();
}

class _ExpertSelectionScreenState extends State<ExpertSelectionScreen> {
  final DatabaseReference _expertsRef = FirebaseDatabase.instance.ref('expert_profiles');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentFarmerUser;
  List<Map<String, dynamic>> _experts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentFarmerUser = _auth.currentUser;
    _fetchExperts();
  }

  void _fetchExperts() {
    if (_currentFarmerUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "You must be logged in to view experts.";
      });
      return;
    }

    _expertsRef.orderByChild('isVerified').equalTo(true).onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedExperts = [];
        data.forEach((key, value) {
          if (value is Map) {
            fetchedExperts.add({
              'id': key, // Firebase Auth UID of the expert
              'name': value['name'] ?? 'N/A',
              'expertiseArea': value['expertiseArea'] ?? 'N/A',
              'contactHandle': value['contactHandle'] ?? 'N/A',
              'isVerified': value['isVerified'] ?? false,
            });
          }
        });
        setState(() {
          _experts = fetchedExperts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _experts = [];
          _isLoading = false;
          _errorMessage = "No verified experts found.";
        });
      }
    }, onError: (error) {
      print("Error fetching experts: $error");
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load experts: $error";
      });
    });
  }

  // Generates a consistent chat room ID for two users
  String _generateChatRoomId(String user1Uid, String user2Uid) {
    // Sort UIDs alphabetically to ensure consistency regardless of who initiates
    List<String> uids = [user1Uid, user2Uid];
    uids.sort();
    return '${uids[0]}_${uids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact an Expert'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                    ),
                  ),
                )
              : _experts.isEmpty
                  ? const Center(
                      child: Text(
                        'No verified experts available at the moment. Please check back later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _experts.length,
                      itemBuilder: (context, index) {
                        final expert = _experts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              if (_currentFarmerUser != null) {
                                final String chatRoomId = _generateChatRoomId(_currentFarmerUser!.uid, expert['id']);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatRoomId: chatRoomId,
                                      chatTitle: 'Chat with ${expert['name']}',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You must be logged in to start a chat.'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expert['name'],
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Expertise: ${expert['expertiseArea']}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact: ${expert['contactHandle']}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(Icons.message, color: Theme.of(context).primaryColor, size: 28),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}