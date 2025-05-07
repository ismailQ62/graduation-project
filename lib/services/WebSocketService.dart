import 'package:web_socket_channel/io.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  late IOWebSocketChannel _channel;
  WebSocketService._internal(){
    _channel = IOWebSocketChannel.connect('ws://192.168.1:81');
    }
  IOWebSocketChannel get channel => _channel;
  }