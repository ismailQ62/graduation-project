import 'package:flutter/material.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';

import 'package:lorescue/models/channel_model.dart';
class ChatScreen extends StatefulWidget {
 final Channel channel;
   ChatScreen({Key? key, required this.channel}):super(key:key );//1

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  late final int _channelId;//2



  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

    List<Map<String, dynamic>> _messages = [];
    List<Map<String, dynamic>> channelmessages = [];//4 
  Map<String, dynamic>? _currentUser;
  String _messageType = "Chat";



@override
void initState() {
  super.initState();
  _channelId = widget.channel.id!;
  _loadCurrentUser();
  _loadMessages();
  _loadMessageForChannel(_channelId);

  _channel.stream.listen((message) async {
    final receivedMessage = message.toString();
    final jsonMessage = jsonDecode(receivedMessage);

    final senderId = jsonMessage["senderID"] ?? "ESP32";
    final content = jsonMessage["content"] ?? receivedMessage;
    final timestamp = DateTime.now().toIso8601String();
    final msgType = jsonMessage["type"] ?? "unknown";

    await _dbService.insertMessage(
      sender: senderId,
      text: content,
      timestamp: timestamp,
      type: _messageType,
      channelId: _channelId,
    );

    setState(() {
      _messages.add({
        'sender': senderId,
        'text': content,
        'timestamp': timestamp,
        'type': msgType,
       'channelId': _channelId,
      });
      _loadMessageForChannel(_channelId);
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
  List<Map<String, dynamic>> dbMessages = await _dbService.getMessagesForChannel(_messageType, _channelId);
  setState(() {
    _messages = List<Map<String, dynamic>>.from(dbMessages);
    channelmessages = _messages;
  });
}

 void _loadMessageForChannel(int channelId) {
  setState(() {
    channelmessages = _messages
        .where((msg) => msg['channelId'] == channelId)
        .toList();
  });
}

  void _sendMessage() async {
  if (_controller.text.isNotEmpty && _currentUser != null) {
    String content = _controller.text.trim();
    DateTime now = DateTime.now();

    String nationalId = _currentUser!['nationalId'];
    String username = _currentUser!['name'];
    String zoneId = "ZONE_A"; // Replace if you store this in the DB

    Map<String, dynamic> messageJson = {
      "type": _messageType,
      "senderID": nationalId,
      "username": username,
      "date":
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      "time":
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      "content": content,
      "channelID": _channelId.toString(), // ✅ Use current channel ID
      "zoneID": zoneId,
      "receiver": "ALL",
      "gps": "32.1234,36.5678", // Replace with actual GPS
    };

    try {
      _channel.sink.add(jsonEncode(messageJson));

      await _dbService.insertMessage(
        sender: nationalId,
        text: content,
        timestamp: now.toIso8601String(),
        type: _messageType,
        channelId: _channelId, // ✅ Save to DB with channelId
      );

      setState(() {
        _messages.add({
          'sender': nationalId,
          'text': content,
          'timestamp': now.toIso8601String(),
          'type': _messageType,
          'channelId': _channelId, // ✅ Keep track of this in state too
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
  final channel = widget.channel;

  return Scaffold(
    appBar: AppBar(title: Text("${channel.name}")),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: channelmessages.length,
            itemBuilder: (context, index) {
              final message = channelmessages[index];
              final senderId = message['sender'] ?? message['senderId']??'Unknown';
              final content = message['text'] ??message['content'] ??'No content';
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
}}