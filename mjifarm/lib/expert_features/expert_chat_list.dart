import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart'; // Adjust this import path as needed

class ExpertChatListScreen extends StatefulWidget {
  const ExpertChatListScreen({super.key});

  @override
  State<ExpertChatListScreen> createState() => _ExpertChatListScreenState();
}

class _ExpertChatListScreenState extends State<ExpertChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentExpertUser;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentExpertUser = _auth.currentUser;
    _listenToExpertChats();
  }

  void _listenToExpertChats() async {
    if (_currentExpertUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Expert not logged in.";
      });
      return;
    }

    // Listen to the expert's list of chat room IDs
    FirebaseDatabase.instance.ref('users/${_currentExpertUser!.uid}/chats').onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> tempConversations = [];
        for (var entry in data.entries) {
          String chatRoomId = entry.key; // The chat room ID (e.g., farmerUID_expertUID)
          // The other UID is the one not matching currentExpertUser.uid
          List<String> uids = chatRoomId.split('_');
          String otherUid = uids.firstWhere((uid) => uid != _currentExpertUser!.uid);

          // Fetch the other user's (farmer's) name
          try {
            DataSnapshot otherUserSnapshot = await FirebaseDatabase.instance.ref('users/$otherUid/name').get();
            String otherUserName = otherUserSnapshot.exists ? otherUserSnapshot.value as String : 'Unknown Farmer';
            
            tempConversations.add({
              'chatRoomId': chatRoomId,
              'otherUid': otherUid, // This is the farmer's UID
              'otherUserName': otherUserName,
            });
          } catch (e) {
            print("Error fetching other user details for $otherUid: $e");
            tempConversations.add({
              'chatRoomId': chatRoomId,
              'otherUid': otherUid,
              'otherUserName': 'Error Loading User',
            });
          }
        }
        setState(() {
          _conversations = tempConversations;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _conversations = [];
          _isLoading = false;
          _errorMessage = "No active conversations.";
        });
      }
    }, onError: (error) {
      print("Error listening to expert chats: $error");
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load conversations: $error";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Conversations'),
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
              : _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No active conversations. Farmers will initiate chats with you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatRoomId: conversation['chatRoomId'],
                                    chatTitle: 'Chat with ${conversation['otherUserName']}',
                                    // Corrected UIDs for ChatScreen
                                    farmerUid: conversation['otherUid'], // 'otherUid' is the farmer's UID in this context
                                    expertUid: _currentExpertUser!.uid, // Current user (expert) is the expert UID
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chat with ${conversation['otherUserName']}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor, size: 20),
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