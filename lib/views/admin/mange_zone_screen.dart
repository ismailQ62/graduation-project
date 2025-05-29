import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:lorescue/services/database/zone_service.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ManageZonesScreen extends StatefulWidget {
  const ManageZonesScreen({super.key});

  @override
  _ManageZonesScreenState createState() => _ManageZonesScreenState();
}

class _ManageZonesScreenState extends State<ManageZonesScreen> {
  List<Zone> zones = [];
  List<Zone> filteredZones = [];
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  final webSocketService = WebSocketService();
  Timer? _connectivityTimer;
  final info = NetworkInfo();
  Zone _zone = Zone(id: '', name: 'Default Zone');
  String? _currentZoneId;
  bool zoneReceived = false;
  Map<String, Timer> zoneTimers = {};
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
    _loadCurrentUser();
    _loadInitialZone();
    fetchZones().then((_) {
      sendZoneCheck();
      printAllZonesFromDb();
    });
    _startConnectivityCheck();
  }

  Future<void> printAllZonesFromDb() async {
    final List<Map<String, dynamic>> zones = await _dbService.getZones();

    for (final zone in zones) {
      print(
        'ID: ${zone['id']}, Name: ${zone['name']}, '
        'Lat: ${zone['latitude']}, Lng: ${zone['longitude']}, '
        'Status: ${zone['status']}',
      );
    }
  }

  void _listenToWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = {'nationalId': user.nationalId, 'name': user.name};
      });
    } else {
      debugPrint("No current user found.");
    }
  }

  void sendZoneCheck() {
    for (var zone in zones) {
      if (zone.name == _currentZoneId) {
        setState(() {
          zone.status = 'Connected ✅';
          zone.notifiedDisconnected = false;
        });
        zoneTimers[zone.name]?.cancel();
      } else {
        setState(() {
          zone.status = 'Disconnected ❌';
        });
        zoneTimers[zone.name]?.cancel();
        resetZoneTimeout(zone.name);
      }
    }

    Map<String, dynamic> message = {"type": "ZonesCheck"};
    webSocketService.send(json.encode(message));
  }

  void resetZoneTimeout(String zoneName) {
    zoneTimers[zoneName]?.cancel();
    zoneTimers[zoneName] = Timer(Duration(seconds: 15), () {
      // Check if the widget is still mounted before updating state
      if (!mounted) {
        return;
      }
      final zone = zones.firstWhere(
        (z) => z.name.trim().toLowerCase() == zoneName.trim().toLowerCase(),
      );
      setState(() {
        zone.status = 'Disconnected ❌';
        if (zone.notifiedDisconnected == false) {
          zone.notifiedDisconnected = true;
          NotificationController.showNotification(
            title: 'Zone Disconnected',
            body: 'Zone $zoneName has been disconnected.',
            sound: 'default',
          );
        }
      });
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      final type = decoded['type'] ?? '';
      final senderZone = decoded['senderZone'] ?? '';
      final receiverZone = decoded['receiverZone'] ?? '';
      double latitude =
          decoded['lat'] != null ? (decoded['lat'] as num).toDouble() : 0.0;
      double longitude =
          decoded['lng'] != null ? (decoded['lng'] as num).toDouble() : 0.0;

      if (type == 'ZonesCheck' || type == 'ZoneAnnounce') {
        final zoneName = (type == 'ZonesCheck') ? senderZone : receiverZone;

        if (zoneName.isEmpty) {
          print("❌ Received $type with empty zone name");
          return;
        }

        Zone? zone = zones.firstWhere(
          (z) => z.name.trim().toLowerCase() == zoneName.trim().toLowerCase(),
          orElse: () {
            final newZone = Zone(
              id: zoneName,
              name: zoneName,
              status: 'Connected ✅',
              latitude: latitude,
              longitude: longitude,
              notifiedDisconnected: false,
            );
            addZone(zoneName);
            setState(() {
              zones.add(newZone);
            });
            return newZone;
          },
        );

        setState(() {
          zone.status = 'Connected ✅';
          zone.latitude = latitude;
          zone.longitude = longitude;
          zone.notifiedDisconnected = false;
        });
        resetZoneTimeout(zoneName);
      }
    } catch (e) {
      print("Error handling WebSocket message: $e");
    }
  }

  bool isConnectedToLorescue = false;

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      String? ssid = await info.getWifiName();
      bool currentlyConnected = (ssid != null && ssid.contains("Lorescue"));

      if (currentlyConnected) {
        if (!isConnectedToLorescue) {
          isConnectedToLorescue = true;
        }
        sendZoneCheck();
      } else {
        if (isConnectedToLorescue) {
          isConnectedToLorescue = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You are disconnected from LoRescue network"),
            ),
          );
        }
      }
    });
  }

  void _loadInitialZone() {
    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: user.connectedZone!);
      });
    }
  }

  Future<void> fetchZones() async {
    final zoneService = ZoneService();
    final fetchedZones = await zoneService.getAllZones();
    setState(() {
      zones = fetchedZones;
      filteredZones = fetchedZones;
    });
    sendZoneCheck();
  }

  void searchZones(String query) {
    final results =
        zones.where((zone) {
          return zone.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    setState(() {
      filteredZones = results;
    });
  }

  Future<void> deleteZone(Zone zone) async {
    await ZoneService().deleteZone(zone.id);

    fetchZones();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${zone.name} deleted successfully!")),
    );
  }

  void addZone(String zoneName) async {
    if (zoneName.isNotEmpty) {
      final newZone = Zone(id: zoneName, name: zoneName);
      bool flag = await ZoneService().addZone(newZone);
      if (flag) {
        fetchZones();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("New zone added successfully! $zoneName")),
        );
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    WebSocketService().removeListener(_handleWebSocketMessage);
    _connectivityTimer?.cancel();
    for (var timer in zoneTimers.values) {
      timer.cancel();
    }
    zoneTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Zones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchZones),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: searchZones,
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                filteredZones.isEmpty
                    ? const Center(child: Text('No zones found.'))
                    : ListView.builder(
                      itemCount: filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = filteredZones[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(zone.name),
                            subtitle: Text(
                              'ID: ${zone.id}\tStatus: ${zone.status}\n Latitude: ${zone.latitude}\tLongitude: ${zone.longitude}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete Zone'),
                                        content: Text(
                                          'Are you sure you want to delete the zone "${zone.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              deleteZone(zone);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Add Zone'),
                        content: TextField(
                          onChanged: (value) {},
                          decoration: const InputDecoration(
                            hintText: 'Enter zone name',
                          ),
                          controller: TextEditingController(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final zoneName =
                                  "New Zone"; // Replace with text controller value
                              addZone(zoneName);
                              Navigator.pop(context);
                            },
                            child: const Text('Add Zone'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('Add Zone'),
            ),
          ),
        ],
      ),
    );
  }
}
