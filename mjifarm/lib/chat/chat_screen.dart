import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NEW: Import Firebase Storage
import 'package:image_picker/image_picker.dart'; // NEW: Import Image Picker
import 'dart:io'; // NEW: For File operations

import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatTitle; 

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('chats');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _currentUserName = 'Anonymous';
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_currentUser == null) {
      print("User not logged in. Cannot initialize chat.");
      setState(() {
        _isLoadingMessages = false;
      });
      return;
    }

    // Fetch current user's name from Realtime Database
    try {
      DataSnapshot userSnapshot = await FirebaseDatabase.instance.ref('users/${_currentUser!.uid}/name').get();
      if (userSnapshot.exists) {
        setState(() {
          _currentUserName = userSnapshot.value as String;
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }

    // Set up listener for messages in the specific chat room
    _messagesRef.child(widget.chatRoomId).child('messages').orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedMessages = [];
        data.forEach((key, value) {
          if (value is Map) {
            fetchedMessages.add(Map<String, dynamic>.from(value));
          }
        });
        // Sort messages by timestamp to ensure correct order
        fetchedMessages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
        setState(() {
          _messages = fetchedMessages;
          _isLoadingMessages = false;
        });
      } else {
        setState(() {
          _messages = [];
          _isLoadingMessages = false;
        });
      }
    }, onError: (error) {
      print("Error listening to messages: $error");
      setState(() {
        _isLoadingMessages = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $error'), backgroundColor: Colors.red),
      );
    });
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    _messageController.clear(); // Clear input field immediately

    try {
      await _messagesRef.child(widget.chatRoomId).child('messages').push().set({
        'senderId': _currentUser!.uid,
        'senderName': _currentUserName,
        'text': text,
        'timestamp': ServerValue.timestamp,
        'type': 'text', // Explicitly 'text' type for text messages
      });
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    if (_currentUser == null) return;

    try {
      await _messagesRef.child(widget.chatRoomId).child('messages').push().set({
        'senderId': _currentUser!.uid,
        'senderName': _currentUserName,
        'imageUrl': imageUrl, // The uploaded image URL
        'timestamp': ServerValue.timestamp,
        'type': 'image', // Explicitly 'image' type for image messages
      });
    } catch (e) {
      print("Error sending image message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _uploadImage() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload images.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Pick image from gallery

    if (pickedFile != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );

        // Create a unique file name for Firebase Storage
        String fileName = 'chat_images/${widget.chatRoomId}/${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        // Upload the file to Firebase Storage
        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Once uploaded, send the message with the image URL
        await _sendImageMessage(downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent!')),
        );
      } catch (e) {
        print("Error uploading image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      // User cancelled image picking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        // Display messages in chronological order, scroll to bottom
                        reverse: false, 
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final bool isMe = message['senderId'] == _currentUser?.uid;
                          return MessageBubble(
                            sender: message['senderName'] ?? 'Unknown',
                            text: message['text'] ?? '', // Will be empty for image messages
                            imageUrl: message['imageUrl'], // Pass imageUrl
                            isMe: isMe,
                            timestamp: message['timestamp'] ?? 0,
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.green), // Changed icon for gallery
                  onPressed: _uploadImage,
                  tooltip: 'Upload Image',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
