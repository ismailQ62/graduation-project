import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/routes.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

late IOWebSocketChannel _channel;

class HomeResponderScreen extends StatefulWidget {
  const HomeResponderScreen({super.key});

  @override
  State<HomeResponderScreen> createState() => _HomeResponderScreenState();
}

class _HomeResponderScreenState extends State<HomeResponderScreen> {
  @override
  void initState() {
    super.initState();
    _channel = IOWebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController _alertMessageController =
              TextEditingController();

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Emergency Alert"),
                content: TextField(
                  controller: _alertMessageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter an alert",
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
                          "type": "ALERT",
                          /*  "senderID":
                              "Responder_123",  */
                          //"username": "Responder",
                          "role": "Responder",
                          "content": message,
                          "timestamp": DateTime.now().toIso8601String(),
                          "zoneID": "ZONE_A",
                          "receiver": "ALL",
                        };
                        // Send Alert over WebSocket
                        _channel.sink.add(jsonEncode(alertPayload));

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
 