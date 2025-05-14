import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/services/database/zone_service.dart'; // ZoneService for database operations
import 'package:lorescue/models/zone_model.dart';
import 'package:network_info_plus/network_info_plus.dart'; // Zone model for data representation

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

  Zone? _receiverZone;
  bool zoneReceived = false;

  @override
  void initState() {
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

    fetchZones();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      String? ssid = await info.getWifiName();
      if (ssid != null && ssid.contains("Lorescue")) {
        try {
          final request = jsonEncode({"type": "ZonesCheck"});
          print("Checking zones...");
          WebSocketService().send(request);
          for (var zone in zones) {
            if (zone.status == 'Disconnected') {
              String zoneName = zone.name;
              NotificationController.showNotification(
                title: 'Zones Check',
                body: '$zoneName disconnected',
                sound: 'emergency_alert',
                id: 2,
              );
            }
          }
        } catch (e) {
          print("Error checking zones: $e");
          setState(() {});
        }
      }else{
        print("Not connected to Lorescue network");
        for (var zone in zones) {
          setState(() {
            zone.status = 'Disconnected';
          });
          String zoneName = zone.name;
              NotificationController.showNotification(
                title: 'Zones Check',
                body: '$zoneName disconnected',
                sound: 'emergency_alert',
                id: 2,
              );
        }
      }
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      final type = decoded['type'] ?? '';
      final senderZone = decoded['senderZone'] ?? '';
      final receiverZone = decoded['receiverZone'] ?? '';
      //_receiverZone = Zone.fromMap(decoded['receivedZone'] ?? {});

      if (type == 'ZonesCheck') {
        setState(() {
          if (!zones.any((z) => z.name == senderZone)) {
            addZone(senderZone);
          } else {
            for (var zone in zones) {
              if (zone.name == senderZone) {
                setState(() {
                  zone.status = 'Connected ✅';
                  print('$zone is connected\n');
                });
              } 
            }
            print('Current Zone is connected');
          }
        });
      } else if (type == 'ZoneAnnounce') {
        if (_currentZoneId != null && _currentZoneId == senderZone) {
          for (var zone in zones) {
            if (zone.name == receiverZone) {
              setState(() {
                zone.status = 'Connected ✅';
                print('$zone is connected\n');
              });
              break;
            } else {
              // Add new zone if it doesn't exist
              if (!zones.any((z) => z.name == receiverZone)) {
                addZone(receiverZone);
                break;
              } else if (zones.any((z) => z.name == receiverZone)) {
                // If the one zone is not received, set it to disconnected
                setState(() {
                  zone.status = 'Disconnected ❌';
                  print('$zone is disconnected\n');
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error handling WebSocket message: $e");
    }
  }

  void _listenToWebSocket() {
    WebSocketService().addListener(_handleWebSocketMessage);
  }

  void _loadInitialZone() {
    final user = AuthService.getCurrentUser();
    if (user != null && user.connectedZone != null) {
      setState(() {
        _zone = Zone(id: user.connectedZone!, name: 'Auto-connected Zone');
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
      await ZoneService().addZone(newZone);
      fetchZones();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("New zone added successfully!")));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    WebSocketService().removeListener(_handleWebSocketMessage);
    _connectivityTimer?.cancel();
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
                              'ID: ${zone.id}\tStatus: ${zone.status}',
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
