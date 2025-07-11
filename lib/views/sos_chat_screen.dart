import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'dart:convert';
import 'package:lorescue/services/gps_service.dart';

class SosChatScreen extends StatefulWidget {
  const SosChatScreen({super.key});

  @override
  _SosChatScreenState createState() => _SosChatScreenState();
}

class _SosChatScreenState extends State<SosChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final GPSService _gpsService = GPSService();
  final webSocketService = WebSocketService();
 
  List<Map<String, dynamic>> _messages = [];
  final user = AuthService.getCurrentUser();
  final String _messageType = "SOS";
  String? _currentZoneId;

  Zone? _receiverZone;
  final List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
    _currentZoneId = user?.connectedZone;
    //_loadMessages();
    _loadMessageForChannel(0, _currentZoneId ?? "Zone_1");
  }

  void _listenToWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
    webSocketService.addListener(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      print("WebSocket message received: $decoded");
      final msgType = decoded['type'] ?? '';
      if (msgType == "SOS") {
        final senderId = decoded["senderID"] ?? "ESP32";
        final senderName = decoded["username"] ?? "Unknown";
        final content = decoded["content"] ?? "No content";
        final timestamp = DateTime.now().toIso8601String();
        final receiverZone = decoded["receiverZone"] ?? "unknown";
        final location = decoded["location"] ?? "0, 0";
        if (user?.nationalId == senderId) {
          return;
        }
        await _dbService.insertMessage(
          senderId: senderId,
          senderName: senderName,
          receiverId: " ",
          content: content,
          timestamp: timestamp,
          type: msgType,
          zoneId: _currentZoneId ?? "Zone_1", //
          channelId: 0,
          receiverZone: receiverZone,
        );

        setState(() {
          _messages.add({
            'senderId': senderId,
            'senderName': senderName,
            'content': content,
            'timestamp': timestamp,
            'type': msgType,
            'zoneId': _currentZoneId ?? "Zone_1",
            'receiverZone': receiverZone,
            'location': location,
          });
        });
        NotificationController.showNotification(
          title: "🚨 SOS",
          body: decoded["content"] ?? "SOS message received",
          sound: "whoop_alert",
          id: 2,
        );
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> dbMessages = await _dbService.getMessages(_messageType,);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
    });
  }
 void _loadMessageForChannel(int channelId, String zoneId) async {
    List<Map<String, dynamic>> dbMessages = await _dbService
        .getMessagesForChannel(
          _messageType,
          channelId,
          zoneId,
        );
    setState(() {
      _messages = List<Map<String, dynamic>>.from(dbMessages);
    });
 }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && user != null) {
      String content = _controller.text.trim();
      DateTime now = DateTime.now();
      String nationalId = user!.nationalId;
      String username = user!.name;
      String zoneId = _currentZoneId ?? "Zone_1";
      String receiverZone = _receiverZone?.name ?? "ALL";

      var location = await _gpsService.getCurrentLocation();
          String locationString;

      if (location == null || (location.latitude == 0 && location.longitude == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to fetch location.")),
        );
        final userData = await _dbService.getUserById(nationalId);
          locationString = userData?['address'] ?? "0, 0";
        
        
      }else{      locationString = "${location.latitude}, ${location.longitude}";
}

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
        "zoneId": zoneId,
        "receiverZone": receiverZone,
        "location": locationString,
      };

      try {
        webSocketService.send(jsonEncode(messageJson));
        await _dbService.insertMessage(
          senderId: nationalId,
          senderName: username,
          receiverId: " ",
          content: content,
          timestamp: now.toIso8601String(),
          type: _messageType,
          zoneId: zoneId, //
          channelId: 0,
          receiverZone: receiverZone,
        );

        setState(() {
          _messages.add({
            'senderId': nationalId,
            'senderName': username,
            'content': content,
            'timestamp': now.toIso8601String(),
            'type': _messageType,
            'receiverZone': receiverZone,
            'location': locationString,
          });
        });
       // user?.latestLocation = "${location.latitude}, ${location.longitude}";
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
    final TextEditingController sosMessageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Send SOS"),
          content: TextField(
            controller: sosMessageController,
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
                String message = sosMessageController.text.trim();
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
    webSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Chat")),
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
                _loadMessageForChannel( 0, newZone?.name ?? _currentZoneId ?? "Zone_1");
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderId = message['senderId'] ?? 'Unknown';
                final senderName = message['senderName'] ?? 'Unknown';
                final content = message['content'] ?? 'No content';
                final timestamp = message['timestamp'] ?? '';
                final location = message['location'] ?? '0, 0';
                final isMe = senderId == user?.nationalId;

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
                      color: isMe ? Colors.red[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$senderName @ $location:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(content),
                        const SizedBox(height: 4),
                        Text(
                          formatTimestamp(timestamp),
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
                      filled: true,
                      fillColor: Color(0xFFFFEBEE),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFB71C1C)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
