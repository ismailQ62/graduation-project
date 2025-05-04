import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:lorescue/models/zone_model.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: 'Auto-connected Zone');
        buttonText = 'Connected to Zone: ${_zone.id}';
      });
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

  void connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));

      channel!.stream.listen(
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
    channel?.sink.close();
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
