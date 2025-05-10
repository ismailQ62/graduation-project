import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'dart:convert';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';

class HomeResponderScreen extends StatefulWidget {
  const HomeResponderScreen({super.key});

  @override
  State<HomeResponderScreen> createState() => _HomeResponderScreenState();
}

class _HomeResponderScreenState extends State<HomeResponderScreen> {
  Zone _zone = Zone(id: '', name: 'Default Zone');
  String buttonText = 'Connect to LoRescue Network';
  final webSocketService = WebSocketService();
  Map<String, dynamic>? _currentUser;
  String? _currentZoneId;

  Zone? _receiverZone;
  final List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];
  Timer? _connectivityTimer;
  final info = NetworkInfo();
  @override
  void initState()  {
    super.initState();
    final user = AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = {'nationalId': user.nationalId, 'name': user.name};
      });
    } else {
      debugPrint("No current user found.");
    }
    _loadInitialZone();

    if (!webSocketService.isConnected) {
      print('🔌 WebSocket not connected. Connecting...');
      webSocketService.connect('ws://192.168.4.1:81');
    } else {
      print('✅ WebSocket already connected.');
    }
    _listenToWebSocket();
    _startConnectivityCheck();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      String? ssid = await info.getWifiName();
      if (ssid != null && ssid.contains("Lorescue")) {
        if (!zoneReceived) {
          setState(() {
            buttonText = 'Requesting Zone Info...';
          });

          try {
            final request = jsonEncode({"type": "NetworkInfo"});
            WebSocketService().send(request);
          } catch (e) {
            print("Error requesting zone info: $e");
            setState(() {
              buttonText = 'Failed to request zone info';
            });
          }
        }
        // If zoneReceived is true, do not overwrite the buttonText
      } else {
        setState(() {
          buttonText = 'Connect to LoRescue Network';
          _zone = Zone(id: '', name: '');
          zoneReceived = false; // Reset so it can request again when reconnected
        });
      }
    });
  }

  void _loadInitialZone() {
    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: 'Auto-connected Zone');
        buttonText = 'Connected to Zone: ${_zone.id}';
      });
    }
  }

  void _listenToWebSocket() {
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  void openWifiSettings() {
    final intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  Widget _buildCategoryBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.blueAccent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.sp, color: Colors.blueAccent),
            SizedBox(height: 10.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDialog() {
    final TextEditingController _alertMessageController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Emergency Alert"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Zone>(
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
                  setState(() => _receiverZone = newZone!);
                },
              ),
              TextField(
                controller: _alertMessageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter an alert",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String message = _alertMessageController.text.trim();
                if (message.isNotEmpty) {
                  final alertPayload = {
                    "type": "Alert",
                    "senderID": _currentUser?['nationalId'] ?? "Unknown",
                    "role": "Responder",
                    "content": message,
                    "timestamp": DateTime.now().toIso8601String(),
                    "zoneID": _zone.id,
                    "receiver": _receiverZone?.name ?? "ALL",
                  };
                  try {
                    WebSocketService().send(jsonEncode(alertPayload));
                    print("Alert sent: ${jsonEncode(alertPayload)}");
                  } catch (e) {
                    print("WebSocket send error: $e");
                  }
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
    //WidgetsBinding.instance.removeObserver(this);
    WebSocketService().removeListener(_handleWebSocketMessage);
    _connectivityTimer?.cancel();

    super.dispose();
  }

  bool zoneReceived = false;

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      final type = decoded['type'] ?? '';
      final senderId = decoded['senderID'] ?? '';

      if (type == 'Alert') {
        if(senderId == _currentUser?['nationalId']) {
          return; // Ignore alerts sent by the current user
        }
        NotificationController.showNotification(
          title: '🚨 Incoming Alert',
          body: decoded['content'] ?? 'No message',
          sound: 'emergency_alert',
          id: 2,
        );
      } else if (type == 'NetworkInfo' && !zoneReceived) {
        setState(() {
          _zone.id = decoded['zoneId'];
          buttonText = 'Connected to Zone: ${_zone.id}';
          zoneReceived = true;
        });

        final user = AuthService.getCurrentUser();
        if (user != null) {
          user.connectedZoneId = _zone.id;
          AuthService.setCurrentUser(user);
          await UserService().updateUserZoneId(user.nationalId, _zone.id);
        }
      }
    } catch (e) {
      print("Error handling WebSocket message: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FC),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Welcome, Responder",
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20.w,
                mainAxisSpacing: 20.h,
                children: [
                  _buildCategoryBox(
                    icon: Icons.verified_user,
                    label: "Upload Credential\nfor Verification",
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.uploadVerification,
                        ),
                  ),
                  _buildCategoryBox(
                    icon: Icons.wifi,
                    label: buttonText,
                    onTap: () async {
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
                      
                      if (!webSocketService.isConnected) {
                        webSocketService.connect('ws://192.168.4.1:81');
                        await Future.delayed(const Duration(milliseconds: 500));
                      }

                      if (webSocketService.isConnected) {
                        webSocketService.send(
                          jsonEncode({"type": "NetworkInfo"}),
                        );
                        setState(() {
                          buttonText = "🔄 Requesting Zone Info...";
                        });
                      } else {
                        setState(() {
                          buttonText = "❌ Could not connect. Check network.";
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _zone.id.isEmpty
              ? null
              : FloatingActionButton(
                onPressed: _showAlertDialog,
                backgroundColor: const Color.fromARGB(255, 244, 228, 58),
                child: Icon(
                  Icons.access_alarms,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 28.sp),
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.uploadVerification,
                  ),
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 28.sp),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.sosChat),
            ),
            SizedBox(width: 48.w),
            IconButton(
              icon: Icon(Icons.map, size: 28.sp),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
            ),
            IconButton(
              icon: Icon(Icons.person, size: 28.sp),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}
