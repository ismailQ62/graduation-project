import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MapController _mapController;
  LatLng _currentLocation = const LatLng(32.49789641037709, 35.98605293585062);
  double _currentZoom = 15.0;
  Zone _zone = Zone(id: '', name: 'Default Zone');

  String buttonText = 'Connect to LoRescue Network';
  WebSocketChannel? channel;
  final webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (!webSocketService.isConnected) {
      print('🔌 WebSocket not connected. Connecting...');
      webSocketService.connect('ws://192.168.4.1:81');
    } else {
      print('✅ WebSocket already connected.');
    }
    webSocketService.addListener(_onWebSocketMessage);

    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: 'Auto-connected Zone');
        buttonText = 'Connected to Zone: ${_zone.id}';
      });
    }
  }

  void _onWebSocketMessage(Map<String, dynamic> message) async {
    final type = message['type'];

    if (type == 'Alert') {
      NotificationController.showNotification(
        title: '🚨 Incoming Alert',
        body: message['content'] ?? 'No message',
        sound: 'emergency_alert',
        id: 2,
      );

      print("📩 Received alert from ESP32: ${message['content']}");
    } else if (type == 'NetworkInfo') {
      setState(() {
        _zone.id = message['zoneId'];
        buttonText = 'Connected to Zone: ${_zone.id}';
      });

      final user = AuthService.getCurrentUser();
      if (user != null) {
        user.connectedZoneId = _zone.id;
        AuthService.setCurrentUser(user);
        await UserService().updateUserZoneId(user.nationalId, _zone.id);
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_currentLocation, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_currentLocation, _currentZoom);
    });
  }

  Future<bool> isESP32Reachable({
    String host = '192.168.4.1',
    int port = 81,
  }) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /*
  void connectToWebSocket() {
    try {
      final channel = WebSocketService().channel;

      channel.stream.listen(
        (message) async {
          try {
            final decoded = jsonDecode(message);

            if (decoded is Map<String, dynamic>) {
              final String type = decoded['type'] ?? '';

              if (type == 'Alert') {
                // Show a local notification for the alert
                NotificationController.showNotification(
                  title: '🚨 Incoming Alert',
                  body: decoded['content'] ?? 'No message',
                  sound: 'emergency_alert',
                  id: 2,
                );
                setState(() {
                  //  _zone.id = decoded['zoneId'];
                  buttonText = decoded['content'] ?? 'Alert received';
                });

                print("Received alert from ESP32: ${decoded['content']}");
              } else if (type == 'NetworkInfo') {
                // Example of another type of message
                setState(() {
                  _zone.id = decoded['zoneId'];
                  buttonText = 'Connected to Zone: ${_zone.id}';
                });

                final user = AuthService.getCurrentUser();
                if (user != null) {
                  user.connectedZoneId = _zone.id;
                  AuthService.setCurrentUser(user);
                  await UserService().updateUserZoneId(
                    user.nationalId,
                    _zone.id,
                  );
                }
              }
            } else if (decoded is String) {
              // In case ESP32 just sends a plain string
              setState(() {
                _zone.id = decoded;
                buttonText = 'Connected to Zone: ${_zone.id}';
              });
            }
          } catch (e) {
            print("Error parsing WebSocket message: $e");
          }
        },
        onError: (error) {
          setState(() => buttonText = 'Connection error');
          print("WebSocket error: $error");
        },
      );
    } catch (e) {
      setState(() => buttonText = 'Connection failed');
      print("WebSocket connection exception: $e");
    }
  }
*/
  void openWifiSettings() {
    final intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  @override
  void dispose() {
    //channel?.sink.close();
    webSocketService.removeListener(_onWebSocketMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Flutter Map
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: _currentZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
              ],
            ),
          ),

          // Zoom Buttons
          Positioned(
            bottom: 100.h,
            right: 20.w,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  mini: true,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                SizedBox(height: 10.h),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  mini: true,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),

          // Connect Button
          Positioned(
            bottom: 30.h,
            left: 20.w,
            right: 20.w,
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  buttonText = "🔍 Checking network...";
                });

                bool reachable = await isESP32Reachable();

                if (!reachable) {
                  setState(() {
                    buttonText = "❌ ESP32 not reachable. Open Wi-Fi.";
                  });
                  openWifiSettings();
                  return;
                }

                // ESP32 is reachable, proceed to connect WebSocket
                if (!webSocketService.isConnected) {
                  webSocketService.connect('ws://192.168.4.1:81');
                  await Future.delayed(const Duration(milliseconds: 500));
                }

                if (webSocketService.isConnected) {
                  webSocketService.send(jsonEncode({"type": "NetworkInfo"}));
                  setState(() {
                    buttonText = "🔄 Requesting Zone Info...";
                  });
                } else {
                  setState(() {
                    buttonText = "❌ Could not connect. Check network.";
                  });
                }
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home);
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.channels,
                  arguments: _zone,
                );
              },
            ),
            SizedBox(width: 48.w),
            IconButton(
              icon: Icon(Icons.map, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.map);
              },
            ),
            IconButton(
              icon: Icon(Icons.person, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ],
        ),
      ),

      // SOS Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.sosChat);
        },
        backgroundColor: Colors.red,
        child: const Text(
          "SOS",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
