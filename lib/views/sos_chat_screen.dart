import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';

class SosChatScreen extends StatefulWidget {
  const SosChatScreen({super.key});

  @override
  _SosChatScreenState createState() => _SosChatScreenState();
}

class _SosChatScreenState extends State<SosChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _currentUser;
  String _messageType = "SOS"; // Default type

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();

    _channel.stream.listen((message) async {
      final received = message.toString();
      final jsonMessage = jsonDecode(received);

      final senderId = jsonMessage["senderID"] ?? "ESP32";
      final content = jsonMessage["content"] ?? received;
      final timestamp = DateTime.now().toIso8601String();
      final msgType = jsonMessage["type"] ?? "unknown";

      await _dbService.insertMessage(
        sender: senderId,
        text: content,
        timestamp: timestamp,
        type: msgType,
      );

      setState(() {
        _messages.add({
          'sender': senderId,
          'text': content,
          'timestamp': timestamp,
          'type': msgType,
        });
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    List<Map<String, dynamic>> users = await _dbService.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _currentUser = users.first; // Simulate the logged-in user
      });
    }
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> dbMessages = await _dbService.getMessages(_messageType);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
    });
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && _currentUser != null) {
      String content = _controller.text.trim();
      DateTime now = DateTime.now();

      String nationalId = _currentUser!['nationalId'];
      String username = _currentUser!['name'];
      String zoneId = "ZONE_A"; // Replace if dynamic

      // Get most recent channel ID from DB
      List<Map<String, dynamic>> dbMessages = await _dbService.getMessages(_messageType);
      String channelId = 
        dbMessages.isNotEmpty
          ? dbMessages.first['channelId'].toString()
          : "1";

      Map<String, dynamic> messageJson = {
        "type": _messageType,
        "senderID": nationalId,
        "username": username,
        "date":
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        "time":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        "content": content,
        "channelID": channelId,
        "zoneID": zoneId,
        "receiver": "ALL",
        "gps": "32.1234,36.5678" // Replace with real GPS
      };

      try {
        _channel.sink.add(jsonEncode(messageJson));

        await _dbService.insertMessage(
          sender: nationalId,
          text: content,
          timestamp: now.toIso8601String(),
          type: _messageType,
        );

        setState(() {
          _messages.add({
            'sender': nationalId,
            'text': content,
            'timestamp': now.toIso8601String(),
            'type': _messageType,
          });
        });

        _controller.clear();
      } catch (e) {
        debugPrint('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LoRescue Chat")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: DropdownButton<String>(
              value: _messageType,
              items: ["SOS", "chat"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text("Type: $value"),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _messageType = newValue!;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderId = message['sender'] ?? 'Unknown';
                final content = message['text'] ?? 'No content';
                final timestamp = message['timestamp'] ?? '';
                final msgType = message['type'] ?? 'unknown';

                return ListTile(
                  title: Text('[$msgType] Sender: $senderId\nMessage: $content'),
                  subtitle: Text('Sent at: $timestamp'),
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
                    controller: _controller,
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
