import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String orderId; // Unique ID for this delivery/order
  final String senderId; // The Driver's ID
  final String receiverId; // The Customer's ID
  final String receiverName; // Customer Name for the AppBar

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    _messageController.clear(); // Clear input immediately for better UX

    try {
      // Add message to Firestore
      await _firestore
          .collection('orders') // Root collection
          .doc(widget.orderId) // Specific Order Document
          .collection('messages') // Sub-collection for chat
          .add({
            'text': messageText,
            'senderId': widget.senderId,
            'receiverId': widget.receiverId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // MESSAGE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .doc(widget.orderId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Newest at bottom
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading messages"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Auto-scroll to bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == widget.senderId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[600] : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          data['text'] ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
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
