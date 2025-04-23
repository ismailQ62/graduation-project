import 'package:flutter/material.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';
import 'package:lorescue/models/zone_model.dart';

import 'package:lorescue/models/channel_model.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;
  final Zone zone;
  ChatScreen({Key? key, required this.channel, required this.zone}): super(key: key); 

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final int _channelId; 
  late final String _zoneId; 

  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> channelmessages = [];
  Map<String, dynamic>? _currentUser;
  String _messageType = "Chat";

  Zone? _receiverZone;

  List<Zone> _zones = [
    Zone(id: '1', name: "Zone1"),
    Zone(id: '2', name: "TeslaZone"),
  ];

  @override
  void initState() {
    super.initState();
    _channelId = widget.channel.id!;
    _zoneId = widget.zone.id;
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
      final receiverZone = jsonMessage["receiverZone"] ?? "unknown";

      await _dbService.insertMessage(
        sender: senderId,
        text: content,
        timestamp: timestamp,
        type: _messageType,
        channelId: _channelId,
        receiverZone : receiverZone,
      );

      setState(() {
        _messages.add({
          'sender': senderId,
          'text': content,
          'timestamp': timestamp,
          'type': msgType,
          'channelId': _channelId,
          'receiverZoneId': receiverZone,
        });
        _loadMessageForChannel(_channelId);
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    List<Map<String, dynamic>> users = await _dbService.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _currentUser = users.first; 
      });
    }
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> dbMessages = await _dbService
        .getMessagesForChannel(_messageType, _channelId); // retreive by channelId, receiverZone
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
      channelmessages = _messages;
    });
  }

  void _loadMessageForChannel(int channelId) {
    setState(() {
      channelmessages =
          _messages.where((msg) => msg['channelId'] == channelId).toList(); // and receiverZone
    });
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && _currentUser != null) {
      String content = _controller.text.trim();
      DateTime now = DateTime.now();

      String nationalId = _currentUser!['nationalId'];
      String username = _currentUser!['name'];
      String zoneId = _zoneId; 
      String receiverZone = _receiverZone?.name ?? "ALL"; 

      Map<String, dynamic> messageJson = {
        "type": _messageType,
        "senderID": nationalId,
        "username": username,
        "date":
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        "time":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        "content": content,
        "channelID": _channelId.toString(), 
        "zoneID": zoneId,
        "receiverZone": receiverZone,
        "gps": "32.1234,36.5678", // Replace with actual GPS
      };

      try {
        _channel.sink.add(jsonEncode(messageJson));

        await _dbService.insertMessage(
          sender: nationalId,
          text: content,
          timestamp: now.toIso8601String(),
          type: _messageType,
          channelId: _channelId, 
          receiverZone: receiverZone, 
        );

        setState(() {
          _messages.add({
            'sender': nationalId,
            'text': content,
            'timestamp': now.toIso8601String(),
            'type': _messageType,
            'channelId': _channelId,
            'receiverZoneId': receiverZone,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: DropdownButton<Zone>(
              hint: const Text("Select Zone"),
              value: _receiverZone,
              isExpanded: true,
              items:
                  _zones.map((Zone zone) {
                    return DropdownMenuItem<Zone>(
                      value: zone,
                      child: Text("Zone: ${zone.name}"),
                    );
                  }).toList(),
              onChanged: (Zone? newZone) {
                setState(() {
                  _receiverZone = newZone!;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: channelmessages.length,
              itemBuilder: (context, index) {
                final message = channelmessages[index];
                final senderId =
                    message['sender'] ?? message['senderId'] ?? 'Unknown';
                final content =
                    message['text'] ?? message['content'] ?? 'No content';
                final timestamp = message['timestamp'];
                final receiverZoneId = message['receiverZoneId'] ?? message['receiverZone'] ?? 'ALL';

                return ListTile(
                  title: Text('Sender: $senderId\nMessage: $content \nZone: $receiverZoneId'),
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
