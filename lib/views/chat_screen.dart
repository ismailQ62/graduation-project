import 'package:flutter/material.dart';
import 'package:lorescue/services/esp32_http_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ESP32HttpService _httpService = ESP32HttpService();
  final TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text;
      setState(() {
        _messages.add("You: $message");
      });

      bool success = await _httpService.sendMessage(message);
      if (!success) {
        setState(() {
          _messages.add("⚠️ Failed to send message.");
        });
      }
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: "Type a message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}







// chat screen with store messages but not working correctly 

/* import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/services/esp32_http_service.dart';
import 'package:lorescue/services/database/message_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ESP32HttpService _httpService = ESP32HttpService();
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();

  List<Message> _messages = [];
  int? _channelId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _channelId = args;
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_channelId == null) return;
    final messages = await _messageService.getMessagesByChannel(_channelId!);
    setState(() {
      _messages = messages;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channelId == null) return;

    final now = DateTime.now().toIso8601String();

    final message = Message(
      senderId: "User123", //  Replace with real user
      receiverId: "Receiver456",
      content: text,
      timestamp: now,
      channelId: _channelId!,
    );

    final success = await _httpService.sendMessage(text);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Failed to send to ESP32")),
      );
    }

    await _messageService.sendMessage(message);
    _messageController.clear();
    await _loadMessages();
  }

  String _formatTimestamp(String iso) {
    final time = DateTime.tryParse(iso);
    return time != null ? DateFormat.Hm().format(time) : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty
                    ? const Center(child: Text("No messages yet"))
                    : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.senderId == "1234567890";
                        return ListTile(
                          title: Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Text(msg.content),
                                  Text(
                                    _formatTimestamp(msg.timestamp),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: "Type a message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} */