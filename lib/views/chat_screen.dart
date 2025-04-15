import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();

    _channel.stream.listen((message) async {
      final receivedMessage = message.toString();
      final senderId = "ESP32";
      final timestamp = DateTime.now().toIso8601String();

      await _dbService.insertMessage(
        sender: senderId,
        text: receivedMessage,
        timestamp: timestamp,
      );

      setState(() {
        _messages.add({
          'sender': senderId,
          'text': receivedMessage,
          'timestamp': timestamp,
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
    List<Map<String, dynamic>> dbMessages = await _dbService.getMessages();
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
      String zoneId = "ZONE_A"; // Replace if you store this in the DB

      // Get most recent channel ID if any
      List<Map<String, dynamic>> dbMessages = await _dbService.getMessages();
      String channelId = dbMessages.isNotEmpty
          ? dbMessages.first['channelId'].toString()
          : "1";

      Map<String, dynamic> messageJson = {
        "senderID": nationalId,
        "username": username,
        "date": "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        "time": "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        "content": content,
        "channelID": channelId,
        "zoneID": zoneId,
        "receiver": "ALL",
        "gps": "32.1234,36.5678" // Replace with actual GPS
      };

      try {
        _channel.sink.add(jsonEncode(messageJson));

        await _dbService.insertMessage(
          sender: nationalId,
          text: content,
          timestamp: now.toIso8601String(),
        );

        setState(() {
          _messages.add({
            'sender': nationalId,
            'text': content,
            'timestamp': now.toIso8601String(),
          });
        });

        _controller.clear();
      } catch (e) {
        debugPrint('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message. Please try again.')),
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
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderId = message['sender'] ?? 'Unknown';
                final content = message['text'] ?? 'No content';
                final timestamp = message['timestamp'];

                return ListTile(
                  title: Text('Sender: $senderId\nMessage: $content'),
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
