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
