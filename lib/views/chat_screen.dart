import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lorescue/services/database/database_service.dart';

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
  String? _currentUserId;

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

  void _loadCurrentUser() async {
    List<Map<String, dynamic>> users = await _dbService.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _currentUserId =
            users.first['id']
                .toString(); // Assume first user is the logged-in user
      });
    }
  }

  Future<void> _loadMessages() async {
    List<Map<String, dynamic>> dbMessages = await _dbService.getMessages();

    setState(() {
      _messages = List<Map<String, dynamic>>.from(
        dbMessages,
      ); // Ensures mutability
    });
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty && _currentUserId != null) {
      String message = _controller.text.trim();
      String timestamp = DateTime.now().toIso8601String();

      try {
        _channel.sink.add(message);
        await _dbService.insertMessage(
          sender: _currentUserId!,
          text: message,
          timestamp: timestamp,
        );

        setState(() {
          _messages.add({
            'sender': _currentUserId,
            'text': message,
            'timestamp': timestamp,
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
                final senderId = message['senderId'];
                final content = message['content'];
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












/*
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:intl/intl.dart'; //this

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late IOWebSocketChannel _channel;
  List<Map<String, String>> _messages = [];
  bool _isConnected = false;
  String _statusMessage = "Connecting..."; // Debug status on UI

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');
      _channel.stream.listen(
        (message) {
          _updateStatus("Connected ✅");
          _processReceivedMessage(message);
        },
        onError: (error) {
          _updateStatus("Connection Error ❌");
          _showSnackbar("WebSocket Error: $error");
          _isConnected = false;
        },
        onDone: () {
          _updateStatus("Disconnected 🔴");
          _isConnected = false;
          Future.delayed(Duration(seconds: 5), _connectWebSocket); // Auto-reconnect
        },
      );
      _isConnected = true;
      _updateStatus("Connected ✅");
    } catch (e) {
      _updateStatus("Failed to Connect ❌");
      _showSnackbar("WebSocket Connection Failed: $e");
      _isConnected = false;
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _processReceivedMessage(String message) {
    List<String> parts = message.split('|');
    if (parts.length == 3) {
      setState(() {
        _messages.add({
          "sender": parts[1],
          "text": parts[2],
          "timestamp": _formatTimestamp(parts[0]),
        });
      });
    }
  }

  String _formatTimestamp(String millis) {
    int time = int.tryParse(millis) ?? 0;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    return DateFormat('hh:mm a').format(date); // Example: "03:45 PM"
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _isConnected) {
      String message = "${DateTime.now().millisecondsSinceEpoch}|User|${_controller.text}";
      try {
        _channel.sink.add(message);
        setState(() {
          _messages.add({
            "sender": "You",
            "text": _controller.text,
            "timestamp": _formatTimestamp(DateTime.now().millisecondsSinceEpoch.toString()),
          });
        });
      } catch (e) {
        _showSnackbar("Error sending message: $e");
      }
      _controller.clear();
    } else {
      _showSnackbar("Not connected to WebSocket!");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Status: $_statusMessage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg["sender"]!, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(msg["text"]!),
                  trailing: Text(msg["timestamp"]!, style: TextStyle(fontSize: 12)),
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
                    decoration: InputDecoration(labelText: "Enter message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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

*/

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