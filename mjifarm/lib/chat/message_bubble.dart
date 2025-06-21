import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final String? imageUrl; // Optional image URL
  final bool isMe;
  final int timestamp;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.text,
    this.imageUrl, // Make it nullable
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final String formattedTime = DateFormat('jm').format(messageTime);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(
              sender,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black54,
              ),
            ),
          const SizedBox(height: 4.0),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                  ),
            elevation: 5.0,
            color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty) // Display image if URL is present
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        imageUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: Column( 
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.grey),
                              Text('Image Load Error', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (text.isNotEmpty) // Display text if not empty (even if image is present)
                    Padding(
                      padding: EdgeInsets.only(top: imageUrl != null ? 8.0 : 0.0), // Add top padding if image is present
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 5.0),
                  Align(
                    alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black45,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
