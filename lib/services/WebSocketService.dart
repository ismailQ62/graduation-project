import 'package:web_socket_channel/io.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  late IOWebSocketChannel _channel;
  WebSocketService._internal(){
    try {
      _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');
      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
    }
  IOWebSocketChannel get channel => _channel;
  }