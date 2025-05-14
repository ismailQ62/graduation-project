import 'package:flutter/material.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;
  final Zone zone;
  const ChatScreen({super.key, required this.channel, required this.zone});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final int _channelId;
  late final String _zoneId;

  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  //final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');
  IOWebSocketChannel? _channel;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> channelmessages = [];
  Map<String, dynamic>? _currentUser;
  final String _messageType = "Chat";
Zone? _currentZone;
  Zone? _receiverZone;
  WebSocketChannel? channel;
  final webSocketService = WebSocketService();

  final List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];

  @override
  void initState() {
    super.initState();
    //_connectWebSocket();
    if (!webSocketService.isConnected) {
      print('🔌 WebSocket not connected. Connecting...');
      webSocketService.connect('ws://192.168.4.1:81');
    } else {
      print('✅ WebSocket already connected.');
    }
    webSocketService.addListener(_onWebSocketMessage);
    _channelId = widget.channel.id!;
    print ("Channel ID: $_channelId");
    _zoneId = widget.zone.id;
    print ("Zone ID: $_zoneId");
    _currentZone = widget.zone;

    _loadCurrentUser();
    //debugPrintAllMessages();
    _loadMessageForChannel(_channelId, _zoneId);
  }
Future<void> debugPrintAllMessages() async {
  
  final db = await _dbService.database;
  final result = await db.query('messages');

  print("=== All Messages in DB ===");
  for (final row in result) {
    print("Message: ${row['content']}, ZoneID: ${row['zoneId']}, ChannelID: ${row['channelId']}");
  }
  print("===========================");
}

  void _onWebSocketMessage(Map<String, dynamic> message) async {
    final type = message['type'];
    if (type == 'Chat') {
      final senderId = message['senderID'] ?? "ESP32";
      final content = message['content'] ?? 'No content';
      final timestamp = DateTime.now().toIso8601String();
      final msgType = message['type'] ?? 'unknown';
      final receiverZone = message['receiverZone'] ?? 'unknown';
      
      if (_currentUser!['nationalId'] == senderId) {
        return;
      }
      
      await _dbService.insertMessage(
        sender: senderId,
        text: content,
        timestamp: timestamp,
        type: msgType,
        channelId: _channelId,
        receiverZone: receiverZone,
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
        _loadMessageForChannel(_channelId, receiverZone);
      });
    }
  }

  void _connectWebSocket() {
    if (_channel != null) return; // Prevent reconnect while already connected

    try {
      debugPrint("Connecting to WebSocket...");
      _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

      _channel!.stream.listen(
        (message) async {
          debugPrint("Message received: $message");
          final jsonMessage = jsonDecode(message);
          final senderId = jsonMessage["senderID"] ?? "ESP32";
          final content = jsonMessage["content"] ?? message;
          final timestamp = DateTime.now().toIso8601String();
          final msgType = jsonMessage["type"] ?? "unknown";
          final receiverZone = jsonMessage["receiverZone"] ?? "unknown";

          await _dbService.insertMessage(
            sender: senderId,
            text: content,
            timestamp: timestamp,
            type: msgType,
            channelId: _channelId,
            receiverZone: receiverZone,
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
            _loadMessageForChannel(_channelId, receiverZone);
          });
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _showDisconnected();
          _disconnectWebSocket();
          _attemptReconnect();
        },
        onDone: () {
          debugPrint("WebSocket closed by server.");
          _showDisconnected();
          _disconnectWebSocket();
          _attemptReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("WebSocket connect error: $e");
    }
  }

  void _disconnectWebSocket() {
    try {
      _channel?.sink.close();
    } catch (e) {
      debugPrint("Error closing socket: $e");
    } finally {
      _channel = null;
    }
  }

  void _attemptReconnect() async {
    await Future.delayed(Duration(seconds: 5)); // wait before retry
    debugPrint("Attempting to reconnect...");
    _connectWebSocket();
  }

  void _showDisconnected() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnected from server. Please reconnect.'),
      ),
    );
  }

  Future<void> _loadCurrentUser() async {
    /* List<Map<String, dynamic>> users = await _dbService.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _currentUser = users.first;
      });
    } */
    final user = AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = {'nationalId': user.nationalId, 'name': user.name};
      });
    } else {
      debugPrint("No current user found.");
    }
  }


  void _loadMessageForChannel(int channelId, String zoneId) async {
    List<Map<String, dynamic>> dbMessages = await _dbService
        .getMessagesForChannel(_messageType, channelId, zoneId);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
      channelmessages = _messages;
    }); 
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && _currentUser != null) {
      String content = _controller.text.trim();
      DateTime now = DateTime.now();

      String nationalId = _currentUser!['nationalId'];
      String username = _currentUser!['name'];
      String zoneId = _zoneId; // Use the current zone name
      String receiverZone = _receiverZone?.name ?? _zoneId;

      Map<String, dynamic> messageJson = {
        "type": "Chat",
        "senderID": nationalId,
        "username": username,
        "date":
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        "time":
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        "content": content,
        "channelID": _channelId.toString(),
        "zoneId": zoneId,
        "receiverZone": receiverZone,
        "gps": "32.1234,36.5678", // Replace with actual GPS
      };

      try {
        //_channel?.sink.add(jsonEncode(messageJson));
        webSocketService.send(jsonEncode(messageJson));
print("Inserting message with zoneId: $receiverZone");

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
    //_channel?.sink.close();
    webSocketService.removeListener(_onWebSocketMessage);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(channel.name)),
            DropdownButton<Zone>(
              hint: const Text("Zone"),
              value: _receiverZone,
              items:
                  _zones.map((Zone zone) {
                    return DropdownMenuItem<Zone>(
                      value: zone,
                      child: Text(zone.name),
                    );
                  }).toList(),
              onChanged: (Zone? newZone) {
                if (newZone != null) {
                  setState(() {
                    _receiverZone = newZone;
                  });
                  _loadMessageForChannel(_channelId, _receiverZone!.name);
print("Selected zone: ${_receiverZone!.name} ${_receiverZone!.id}");
                } else {
                  setState(() {
                    _receiverZone = null;
                  });
                  _loadMessageForChannel(_channelId, _zoneId);
                  print("Selected zone: ${_currentZone!.name}");
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
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
                final receiverZoneId =
                    message['receiverZoneId'] ??
                    message['receiverZone'] ??
                    _zoneId;
                final isMe = senderId == _currentUser?['nationalId'];
                final timeFormatted = formatTimestamp(timestamp);
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$senderId@$receiverZoneId:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(content),
                        const SizedBox(height: 4),
                        Text(
                          timeFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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

  String formatTimestamp(dynamic timestamp) {
    try {
      final dt = DateTime.tryParse(timestamp.toString());
      if (dt != null) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    return timestamp.toString();
  }
}
