import 'package:flutter/material.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lorescue/models/user_model.dart';

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
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> channelmessages = [];
  Map<String, dynamic>? _currentUser;
  final String _messageType = "Chat";
  //late final String _messageType;
  Zone? _currentZone;
  Zone? _receiverZone;
  final webSocketService = WebSocketService();
  List<User> _users = [];
  User? _selectedUser;
  final List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
    _channelId = widget.channel.id!;
    print("Channel ID: $_channelId");
    _zoneId = widget.zone.id;
    _currentZone = widget.zone;
    //_messageType = widget.channel.type.toLowerCase();
    _loadCurrentUser();
    _loadUsers();
    _loadMessageForChannel(_channelId, _zoneId);
    debugPrintAllMessages();
  }

  void _listenToWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  Future<void> debugPrintAllMessages() async {
    final db = await _dbService.database;
    final result = await db.query('messages');

    print("=== All Messages in DB ===");
    for (final row in result) {
      print("Message: ${row['content']}, ZoneID: ${row['zoneId']}, ChannelID: ${row['channelId']}",);
    }
    print("===========================");
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) async {
    print("Received message: $message");
    final type = message['type'];
    if (type == 'Chat') {
      final senderId = message['senderID'] ?? "ESP32";
      final senderName = message['username'] ?? "Unknown Sender";
      final content = message['content'] ?? 'No content';
      final timestamp = DateTime.now().toIso8601String();
      final msgType = message['type'] ?? 'unknown';
      final receiverZone = message['receiverZone'] ?? 'unknown';
      final receiverId = message['receiverId'] ?? '';

      if (_currentUser!['nationalId'] == senderId) {
        return;
      }

      await _dbService.insertMessage(
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        content: content,
        timestamp: timestamp,
        type: msgType,
        zoneId: _zoneId,
        channelId: _channelId,
        receiverZone: receiverZone,
      );

      setState(() {
        _messages.add({
          'senderId': senderId,
          'senderName': senderName,
          'content': content,
          'timestamp': timestamp,
          'type': msgType,
          'channelId': _channelId,
          'zoneId': _zoneId,
          'receiverZone': receiverZone,
          'receiverId': receiverId,
        });
        channelmessages = List<Map<String, dynamic>>.from(_messages);
      });
        print("Updated messages: $channelmessages"); // doesn't reach here
    }
  }

  Future<void> _loadUsers() async {
    List<Map<String, dynamic>> users = await _dbService.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _users = users.map((user) => User.fromMap(user)).toList();
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = {
          'nationalId': user.nationalId,
          'name': user.name,
          'role': user.role,
          'connectedZoneId': user.connectedZone,
        };
      });
    } else {
      debugPrint("No current user found.");
    }
  }

  void _loadMessageForContacts(int channelId, String zoneId) async {
    List<Map<String, dynamic>> dbMessages = await _dbService
        .getMessagesForContacts(
          _messageType,
          channelId,
          zoneId,
          _selectedUser?.nationalId,
        );
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
      channelmessages = _messages;
    });
  }
   void _loadMessageForChannel(int channelId, String zoneId) async {
    List<Map<String, dynamic>> dbMessages = await _dbService
        .getMessagesForChannel(
          _messageType,
          _channelId,
          zoneId,
        );
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
      channelmessages = _messages;
    });
    print("Loaded messages for channel $_channelId: $channelmessages");
      }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && _currentUser != null) {
      final String role = _currentUser!['role'] ?? 'Unknown';

      // Block non-Responders from sending in Alert Channel
      if (_channelId == 2 && role != 'Responder') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only Responders can send messages in Alert Channel.',
            ),
          ),
        );
        return;
      }

      String content = _controller.text.trim();
      DateTime now = DateTime.now();
      String nationalId = _currentUser!['nationalId'];
      String username = _currentUser!['name'];
      String zoneId = _zoneId;
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
        "receiverId": _selectedUser?.nationalId ?? '',
        "location": "32.1234,36.5678",
      };

      try {
        webSocketService.send(jsonEncode(messageJson));
        await _dbService.insertMessage(
          senderId: nationalId,
          senderName: username,
          receiverId: _selectedUser?.nationalId ?? '',
          content: content,
          timestamp: now.toIso8601String(),
          type: _messageType,
          zoneId: _zoneId,
          channelId: _channelId,
          receiverZone: receiverZone,
        );

        setState(() {
          _messages.add({
            'senderId': nationalId,
            'senderName': username,
            'content': content,
            'timestamp': now.toIso8601String(),
            'type': _messageType,
            'channelId': _channelId,
            'zoneId': _zoneId,
            'receiverZone': receiverZone,
            'receiverId': _selectedUser?.nationalId ?? '',
          });
          channelmessages = List<Map<String, dynamic>>.from(_messages);
        });

        _controller.clear();
      } catch (e) {
        debugPrint('Error sending message: \$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    webSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    return Scaffold(
      appBar: AppBar(
        title:
            widget.channel.id == 4 // Contacts Channel
                ? Row(
                  children: [
                    Expanded(
                      child: DropdownButton<User>(
                        isExpanded: true,
                        hint: const Text("Select User"),
                        value: _selectedUser,
                        items:
                            _users.map((User user) {
                              return DropdownMenuItem<User>(
                                value: user,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "${user.name}_${user.nationalId}",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (User? newUser) {
                          setState(() => _selectedUser = newUser);
                          _loadMessageForContacts(
                            _channelId,
                            _receiverZone?.name ?? _zoneId,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<Zone>(
                        isExpanded: true,
                        hint: const Text("Zone"),
                        value: _receiverZone,
                        items:
                            _zones.map((Zone zone) {
                              return DropdownMenuItem<Zone>(
                                value: zone,
                                child: Text(
                                  zone.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (Zone? newZone) {
                          setState(() => _receiverZone = newZone);
                          _loadMessageForContacts(
                            _channelId,
                            newZone?.name ?? _zoneId,
                          );
                        },
                      ),
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.channel.name
                            .replaceAll('Channel', '')
                            .trim(), // ✅ Removes "Channel"
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<Zone>(
                        isExpanded: true,
                        hint: const Text("Zone"),
                        value: _receiverZone,
                        items:
                            _zones.map((Zone zone) {
                              return DropdownMenuItem<Zone>(
                                value: zone,
                                child: Text(
                                  zone.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (Zone? newZone) {
                          setState(() => _receiverZone = newZone);
                          _loadMessageForChannel(
                            _channelId,
                            newZone?.name ?? _zoneId,
                          );
                        },
                      ),
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
                final senderId = message['senderId'] ?? 'Unknown';
                final senderName = message['senderName'] ?? 'Unknown Sender';
                final content = message['content'] ?? 'No content';
                final timestamp = message['timestamp'] ?? (message['date'] != null && message['time'] != null? "${message['date']} ${message['time']}": null);
                final timeFormatted = formatTimestamp(timestamp);
                final receiverZoneId = message['receiverZoneId'] ?? message['receiverZone'] ?? _zoneId;
                final userZone = _currentUser?['connectedZoneId'];
                final isMe = senderId == _currentUser?['nationalId'];
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
                          "$senderName@$userZone:",
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
            child: buildMessageInput(),
          ),
        ],
      ),
    );
  }

  Widget buildMessageInput() {
    if (_channelId == 2 && _currentUser?['role'] != 'Responder') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Type a message"),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
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
