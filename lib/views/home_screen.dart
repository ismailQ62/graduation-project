import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/controllers/notification_controller.dart';

//import 'package:lorescue/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MapController _mapController;
  // ignore: prefer_final_fields
  LatLng _currentLocation = const LatLng(32.49789641037709, 35.98605293585062);
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
        ],
      ),

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

      //sos button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController _sosMessageController =
              TextEditingController();

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Send SOS "),
                content: TextField(
                  controller: _sosMessageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter SOS message",
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
                      String message = _sosMessageController.text.trim();
                      if (message.isNotEmpty) {
                        NotificationController.showNotification(
                          title: "🚨 SOS ",
                          body: message,
                          //  role: "Individual",
                          sound: "whoop_alert",
                          id: 2,
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
        backgroundColor: Colors.red,
        child: Text(
          "SOS",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}


//if we want to use esp32 maybe work correctly with it
/* channel.stream.listen((message) {
  final decoded = jsonDecode(message);

  if (decoded['type'] == 'alert' && decoded['role'] == 'Responder') {
    NotificationController.showNotification(
      title: "🚨 EMR Alert",
      body: decoded['message'],
      role: "Individual", // so it plays SOS sound
      id: 888,
    );
  }
}); */

//  cpp code for esp32
/* webSocket.onEvent([](WebSocket &server, WebSocketClient &client, WSEventType type, uint8_t *data, size_t len) {
  if (type == WStype_TEXT) {
    String message = String((char *)data);
    Serial.println("Received: " + message);
    
    // Broadcast to ALL connected clients
    for (auto &c : server.getClients()) {
      if (c.connected()) {
        c.sendTXT(message); // forward it
      }
    }
  }
}); */