import 'package:flutter/material.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/auth_service.dart';
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
  String _messageType = "SOS";
  String? _currenZoneId;

  Zone? _receiverZone;
  List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _currenZoneId = AuthService.getCurrentUser()?.connectedZone;

    _channel.stream.listen((message) async {
      final received = message.toString();
      final jsonMessage = jsonDecode(received);

      final senderId = jsonMessage["senderID"] ?? "ESP32";
      final content = jsonMessage["content"] ?? received;
      final timestamp = DateTime.now().toIso8601String();
      final msgType = jsonMessage["type"] ?? "unknown";
      final receiverZone = jsonMessage["receiverZone"] ?? "unknown";

      await _dbService.insertMessage(
        sender: senderId,
        text: content,
        timestamp: timestamp,
        type: msgType,
        channelId: 0,
        receiverZone: receiverZone,
      );

      setState(() {
        _messages.add({
          'sender': senderId,
          'text': content,
          'timestamp': timestamp,
          'type': msgType,
          'receiverZoneId': receiverZone,
        });
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
    List<Map<String, dynamic>> dbMessages = await _dbService.getMessages(
      _messageType,
    );
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
      String zoneId =
          _currenZoneId ?? "Zone_1"; // Default zone if not connected
      String receiverZone = _receiverZone?.name ?? "ALL";

      /* List<Map<String, dynamic>> dbMessages = await _dbService.getMessages(
        _messageType,
      );
      String channelId =
          dbMessages.isNotEmpty
              ? dbMessages.first['channelId'].toString()
              : "1"; */

      Map<String, dynamic> messageJson = {
        "type": _messageType,
        "senderID": nationalId,
        "username": username,
        "date":
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        "time":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        "content": content,
        "channelID": "0",
        "zoneID": zoneId,
        "receiverZone": receiverZone,
        "gps": "32.1234,36.5678",
      };

      try {
        _channel.sink.add(jsonEncode(messageJson));

        await _dbService.insertMessage(
          sender: nationalId,
          text: content,
          timestamp: now.toIso8601String(),
          type: _messageType,
          channelId: 0,
          receiverZone: receiverZone,
        );

        setState(() {
          _messages.add({
            'sender': nationalId,
            'text': content,
            'timestamp': now.toIso8601String(),
            'type': _messageType,
            'receiverZoneId': receiverZone,
          });
        });

        // if sending SOS message, show notification

        /*  NotificationController.showNotification(
          title: "New Message Sent",
          body: content,
          sound: "whoop_alert", 
          id: 3, 
        ); */

        _controller.clear();
      } catch (e) {
        debugPrint('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
          ),
        );
      }
    }
  }

  void _showSosDialog() {
    final TextEditingController _sosMessageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Send SOS"),
          content: TextField(
            controller: _sosMessageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter SOS message",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String message = _sosMessageController.text.trim();
                if (message.isNotEmpty) {
                  _controller.text = message;
                  _sendMessage();
                }
                Navigator.of(context).pop();
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Chat")),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4,
                ),
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
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final senderId =
                        message['sender'] ?? message['senderId'] ?? 'Unknown';
                    final content =
                        message['text'] ?? message['content'] ?? 'No content';
                    final timestamp = message['timestamp'] ?? '';
                    final msgType = message['type'] ?? 'unknown';

                    return ListTile(
                      title: Text(
                        '[$msgType] Sender: $senderId\nMessage: $content',
                      ),
                      subtitle: Text('Sent at: $timestamp'),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
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
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                final TextEditingController _sosMessageController =
                    TextEditingController();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Send SOS"),
                      content: TextField(
                        controller: _sosMessageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Enter SOS message",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            String message = _sosMessageController.text.trim();
                            if (message.isNotEmpty) {
                              NotificationController.showNotification(
                                title: "🚨 SOS",
                                body: message,
                                sound: "whoop_alert",
                                id: 2,
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text("Send"),
                        ),
                      ],
                    );
                  },
                );
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.warning_amber_rounded, size: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
