import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
 
import 'message_bubble.dart'; // Adjust this import path as needed

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatTitle;
  final String farmerUid; 
  final String expertUid; 

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatTitle,
    required this.farmerUid, 
    required this.expertUid, 
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
      print("ChatScreen Debug: User not logged in. Cannot initialize chat."); // Added Debug prefix
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
        print("ChatScreen Debug: Current user name fetched: $_currentUserName"); // Added Debug prefix
      } else {
        print("ChatScreen Debug: Current user name not found in DB for ${_currentUser!.uid}."); // Added Debug prefix
      }
    } catch (e) {
      print("ChatScreen Debug: Error fetching user name for ${_currentUser!.uid}: $e"); // Added Debug prefix
    }

    String currentUid = _currentUser!.uid;
    String otherUid = (currentUid == widget.farmerUid) ? widget.expertUid : widget.farmerUid;

    print("ChatScreen Debug: Current UID (Initiator): $currentUid"); // Added Debug prefix
    print("ChatScreen Debug: Other UID (Receiver): $otherUid"); // Added Debug prefix
    print("ChatScreen Debug: Chat Room ID: ${widget.chatRoomId}"); // Added Debug prefix
    print("ChatScreen Debug: Farmer UID (passed to ChatScreen): ${widget.farmerUid}"); // Added Debug prefix
    print("ChatScreen Debug: Expert UID (passed to ChatScreen): ${widget.expertUid}"); // Added Debug prefix


    DatabaseReference currentUserChatRef = FirebaseDatabase.instance.ref('users/$currentUid/chats/${widget.chatRoomId}');
    DatabaseReference otherUserChatRef = FirebaseDatabase.instance.ref('users/$otherUid/chats/${widget.chatRoomId}');

    // --- CRUCIAL CHANGE HERE: ADD .then() and .catchError() blocks ---
    currentUserChatRef.get().then((snapshot) {
      if (!snapshot.exists) {
        currentUserChatRef.set(true).then((_) {
          print("ChatScreen Debug: SUCCESS: Chat room ID added to current user ($currentUid) chats."); // Added success print
        }).catchError((e) {
          print("ChatScreen Debug: ERROR adding chat room ID to current user ($currentUid) chats: $e"); // Added error print
        });
      } else {
        print("ChatScreen Debug: Chat room ID already exists for current user ($currentUid).");
      }
    }).catchError((e) {
      print("ChatScreen Debug: ERROR checking current user chat ref for $currentUid: $e"); // Added error print
    });

    otherUserChatRef.get().then((snapshot) {
      if (!snapshot.exists) {
        otherUserChatRef.set(true).then((_) {
          print("ChatScreen Debug: SUCCESS: Chat room ID added to other user ($otherUid) chats."); // Added success print
        }).catchError((e) {
          print("ChatScreen Debug: ERROR adding chat room ID to other user ($otherUid) chats: $e"); // Added error print
        });
      } else {
        print("ChatScreen Debug: Chat room ID already exists for other user ($otherUid).");
      }
    }).catchError((e) {
      print("ChatScreen Debug: ERROR checking other user chat ref for $otherUid: $e"); // Added error print
    });
    // --- END OF CRUCIAL CHANGE ---


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
      print("ChatScreen Debug: Error listening to messages: $error"); // Added Debug prefix
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
      print("ChatScreen Debug: Error sending message: $e"); // Added Debug prefix
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
      print("ChatScreen Debug: Error sending image message: $e"); // Added Debug prefix
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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );

        String fileName = 'chat_images/${widget.chatRoomId}/${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _sendImageMessage(downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent!')),
        );
      } catch (e) {
        print("ChatScreen Debug: Error uploading image: $e"); // Added Debug prefix
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
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
                        reverse: false,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final bool isMe = message['senderId'] == _currentUser?.uid;
                          return MessageBubble(
                            sender: message['senderName'] ?? 'Unknown',
                            text: message['text'] ?? '',
                            imageUrl: message['imageUrl'],
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
                  icon: const Icon(Icons.image, color: Colors.green),
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