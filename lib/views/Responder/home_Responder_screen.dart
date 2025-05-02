import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//late IOWebSocketChannel _channel;

class HomeResponderScreen extends StatefulWidget {
  const HomeResponderScreen({super.key});

  @override
  State<HomeResponderScreen> createState() => _HomeResponderScreenState();
}

class _HomeResponderScreenState extends State<HomeResponderScreen> {
  Zone _zone = Zone(id: '', name: 'Default Zone');

  String buttonText = 'Connect to LoRescue Network';
  WebSocketChannel? _channel;

  //final _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');

  Zone? _receiverZone;
  //late final String _zoneId;
  String? _currentZoneId;
  List<Zone> _zones = [
    Zone(id: '1', name: "Zone_1"),
    Zone(id: '2', name: "Zone_2"),
    Zone(id: '3', name: "Zone_3"),
  ];

  @override
  void initState() {
    super.initState();
    // _channel = IOWebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));
   // _currentZoneId = AuthService.getCurrentUser()?.connectedZone;

   


    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: 'Auto-connected Zone');
        buttonText = 'Connected to Zone: ${_zone.id}';
      });
    }

  }
   
   void connectToWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));

      _channel!.stream.listen(
        (message) async {
          setState(() {
            _zone.id = message;
            buttonText = 'Connected to Zone: ${_zone.id}';
          });
          final user = AuthService.getCurrentUser();
          if (user != null) {
            user.connectedZoneId = _zone.id;
            AuthService.setCurrentUser(user); // Update local cache

            await UserService().updateUserZoneId(
              user.nationalId,
              _zone.id,
            ); // Update DB
          }
        },
        onError: (error) {
          setState(() {
            buttonText = 'Connection error';
          });
        },
      );
    } catch (e) {
      setState(() {
        buttonText = 'Connection failed';
      });
    }
  }

  void openWifiSettings() {
    final intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }




  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, Responder",
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30.h,
            left: 20.w,
            right: 20.w,
            child: ElevatedButton(
              onPressed: () {
                openWifiSettings();
                Future.delayed(const Duration(seconds: 5), () {
                  connectToWebSocket();
                });
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4,
                      ),
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
                        },
                      ),
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
                        // Local Notification
                        NotificationController.showNotification(
                          title: "⚠️ Alert",
                          body: message,
                          sound: "emergency_alert",
                          id: 1,
                        );

                        //  JSON alert
                        final alertPayload = {
                          "type": "Alert",
                          /*  "senderID":
                              "Responder_123",  */
                          //"username": "Responder",
                          "role": "Responder",
                          "content": message,
                          "timestamp": DateTime.now().toIso8601String(),
                          "zoneID": _zone.id,
                          "receiver": _receiverZone?.name ?? "ALL",
                        };
                        // Send Alert over WebSocket
                        try {
                          _channel?.sink.add(jsonEncode(alertPayload));
                          print("Alert sent: ${jsonEncode(alertPayload)}");
                        } catch (e) {
                          print("WebSocket send error: $e");
                        }

                        /* try {
                          _channel.sink.add(jsonEncode(alertPayload));
                          print(" Responder alert sent to ESP32!");
                        } catch (e) {
                          print("Failed to send alert over WebSocket: $e");
                        } */
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text("Send"),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: const Color.fromARGB(255, 244, 228, 58),
        child: Icon(Icons.access_alarms, color: Colors.white, size: 28.sp),
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
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.verification);
              },
            ),
            IconButton(
              icon: Icon(Icons.chat, size: 28.sp),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.sosChat);
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
    );
  }
}


// WebSocket to broadcast alerts to all clients
 /* void webSocketEvent(uint8_t client_num, WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_TEXT: {
      // ✅ Flutter sends a JSON string (your alertPayload)
      String incomingMessage = String((char*)payload);

      Serial.print("Received from client: ");
      Serial.println(incomingMessage);

      // ✅ Directly broadcast this JSON to all other clients
      webSocket.broadcastTXT(incomingMessage);

      Serial.println("Broadcasted to all clients.");

      break;
    }
    default:
      break;
  } */