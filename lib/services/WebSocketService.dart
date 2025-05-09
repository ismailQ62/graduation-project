import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

typedef OnMessageCallback = void Function(Map<String, dynamic>);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  final List<OnMessageCallback> _listeners = [];

  WebSocketService._internal();

  void connect(String url) {
    if (_isConnected) {
      print('ℹ️ Already connected.');
      return;
    }

    print('📡 Attempting WebSocket connection to $url');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      print('✅ WebSocket connection established');

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = json.decode(data);
            if (decoded is Map<String, dynamic>) {
              for (final listener in _listeners) {
                listener(decoded);
              }
            }
          } catch (e) {
            print("❌ Error decoding message: $e");
          }
        },
        onDone: () {
          _isConnected = false;
          _handleDisconnection();
          print('🔌 WebSocket connection closed');
        },
        onError: (error) {
          _isConnected = false;
          _handleDisconnection();
          print("❌ WebSocket error: $error");
        },
      );
    } catch (e) {
      print('❗Exception in connect(): $e');
    }
  }

  void addListener(OnMessageCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(OnMessageCallback listener) {
    _listeners.remove(listener);
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
  }

  void _handleDisconnection() {
    _isConnected = false;
    print(
      '🔌 Disconnected from WebSocket. Trying to reconnect in 3 seconds...',
    );
    Future.delayed(Duration(seconds: 3), () {
      if (!_isConnected && _channel != null) {
        connect('ws://192.168.4.1:81');
      }
    });
  }
}
