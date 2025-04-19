import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/routes.dart';

class HomeResponderScreen extends StatefulWidget {
  const HomeResponderScreen({super.key});

  @override
  State<HomeResponderScreen> createState() => _HomeResponderScreenState();
}

class _HomeResponderScreenState extends State<HomeResponderScreen> {
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
              /* Text(
                ,
                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                textAlign: TextAlign.center,
              ), */
            ],
          ),
        ),
      ),

      //Alert Button
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
                    hintText: "Enter and alert ",
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
                        NotificationController.showNotification(
                          title: "⚠️ Alert ",
                          body: message,
                          // role: "Responder",
                          sound: "emergency_alert",
                          id: 1,
                        );
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
                Navigator.pushNamed(context, AppRoutes.channels);
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

// send to ESP32
/* onPressed: () {
  String message = _alertMessageController.text.trim();
  if (message.isNotEmpty) {
    
    NotificationController.showNotification(
      title: "⚠️ Alert ",
      body: message,
      sound: "emergency_alert",
      id: 1,
    );

    // ✅ Send to ESP32
    final socket = ESP32SocketService();
    socket.connect();

    final alertPayload = {
      "role": "Responder",
      "type": "alert",
      "message": message,
      "timestamp": DateTime.now().toIso8601String(),
    };

    socket.sendMessage(jsonEncode(alertPayload));
  }

  Navigator.of(context).pop();
},
 */
