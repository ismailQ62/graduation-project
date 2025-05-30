import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/channel_service.dart';
import 'package:lorescue/services/database/user_service.dart';

class ChannelController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final ChannelService _channelService = ChannelService();
  final WebSocketService _webSocketService = WebSocketService();
  final UserService _userService = UserService();
  final Zone zone;
  List<Channel> _channels = [];
  List<User> users = [];
  Map<String, dynamic>? _currentUser;

  ChannelController(this.zone);

  List<Channel> get filteredChannels {
    final search = searchController.text.toLowerCase();
    return _channels
        .where((c) => c.name.toLowerCase().contains(search))
        .toList();
  }

  Future<void> init() async {
    await _loadCurrentUser();
    await _loadChannels();
    _listenToWebSocket();
  }

  Future<void> _loadChannels() async {
    _channels = await _channelService.getAllChannels();
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.getCurrentUser();
    if (user != null) {
      _currentUser = {
        'nationalId': user.nationalId,
        'name': user.name,
        'role': user.role,
        'connectedZoneId': user.connectedZone,
      };
    }
  }

  void _listenToWebSocket() {
    if (!_webSocketService.isConnected) {
      _webSocketService.connect('ws://192.168.4.1:81');
    }
    _webSocketService.addListener(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) {
    final type = decoded['type'] ?? '';
    if (type == "GetUsers") {
      final nationalId = decoded['national_id'] ?? '';
      final name = decoded['name'] ?? '';
      if (!users.any((u) => u.nationalId == nationalId)) {
        final newUser = User(
          name: name,
          nationalId: nationalId,
          password: " ",
          role: " ",
          connectedZoneId: " ",
        );
        users.add(newUser);
        _userService.insertUser(newUser);
        notifyListeners();
      }
    }
  }

  void handleChannelTap(BuildContext context, Channel channel) {
    if (_currentUser?['role'] == "Responder" && channel.id == 4) {
      Navigator.pushNamed(context, AppRoutes.sosChat);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {'channel': channel, 'zone': zone},
      );
      if (channel.id == 4) {
        _webSocketService.send(jsonEncode({'type': 'GetUsers'}));
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _webSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }
}
