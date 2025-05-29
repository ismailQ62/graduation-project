import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/zone_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart';

class ZoneManagerService {
  final WebSocketService _webSocketService = WebSocketService();
  final Map<String, Timer> _zoneTimers = {};
  
  bool isConnectedToLorescue = false;
  late Timer _connectivityTimer;
  final info = NetworkInfo();
  final List<Zone> _zones = [];
  List<Zone> filteredZones = [];
  Function(List<Zone>)? onZonesUpdated;
  List<Zone> get zones => _zones;

  void _listenToWebSocket() {
    if (!_webSocketService.isConnected) {
      _webSocketService.connect('ws://192.168.4.1:81');
    }
    _webSocketService.addListener(handleWebSocketMessage);
  }

  void dispose() {
    _webSocketService.removeListener(
      handleWebSocketMessage,
    ); //WebSocketService() class call instead of _webSocketService
    for (var timer in _zoneTimers.values) {
      timer.cancel();
    }
    _zoneTimers.clear();
  }

  void sendZoneCheck() {
    final message = {"type": "ZonesCheck"};
    _webSocketService.send(json.encode(message));
  }

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
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            SnackBar(
              content: Text("You are disconnected from LoRescue network"),
            ),
          );
        }
      }
    });
  }

  void resetZoneTimeout(String zoneName) {
    _zoneTimers[zoneName]?.cancel();
    _zoneTimers[zoneName] = Timer(Duration(seconds: 15), () {
      final zone = _zones.firstWhere(
        (z) => z.name == zoneName,
        orElse: () => Zone(id: '', name: ''),
      );
      if (zone.name.isEmpty) return;

      zone.status = 'Disconnected ❌';
      if (!zone.notifiedDisconnected) {
        zone.notifiedDisconnected = true;
        NotificationController.showNotification(
          title: 'Zone Disconnected',
          body: 'Zone $zoneName has been disconnected.',
          sound: 'default',
        );
      }
      _notify();
    });
  }

  void handleWebSocketMessage(Map<String, dynamic> decoded) {
    final type = decoded['type'];
    final senderZone = decoded['senderZone'];
    final receiverZone = decoded['receiverZone'];
    final lat = decoded['lat']?.toDouble() ?? 0.0;
    final lng = decoded['lng']?.toDouble() ?? 0.0;

    if (type == 'ZonesCheck' || type == 'ZoneAnnounce') {
      final zoneName = (type == 'ZonesCheck') ? senderZone : receiverZone;
      final index = _zones.indexWhere(
        (z) => z.name.toLowerCase() == zoneName.toLowerCase(),
      );

      if (index == -1) {
        final newZone = Zone(
          id: zoneName,
          name: zoneName,
          status: 'Connected ✅',
          latitude: lat,
          longitude: lng,
        );
        _zones.add(newZone);
        addZone(zoneName);
      } else {
        _zones[index]
          ..status = 'Connected ✅'
          ..latitude = lat
          ..longitude = lng
          ..notifiedDisconnected = false;
        updateZone(zoneName, 'Connected ✅', lat, lng);
      }
      resetZoneTimeout(zoneName);
    }
    _notify();
  }

  void updateUserZone(String zoneName) {
    final user = AuthService.getCurrentUser();
    user?.connectedZoneId = zoneName;
  }

  Future<void> updateZone(
    String zoneName,
    String status,
    double lat,
    double lng,
  ) async {
    ZoneService().updateZone(zoneName, status, lat, lng);
  }

  Future<void> fetchZones() async {
    final fetchedZones = await ZoneService().getAllZones();
    _zones.clear();
    _zones.addAll(fetchedZones);
    filteredZones = List.from(_zones);
    _notify();
  }

  Future<void> addZone(String zoneName) async {
    final newZone = Zone(id: zoneName, name: zoneName);
    final success = await ZoneService().addZone(newZone);
    if (success) {
      await fetchZones();
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("New zone added successfully! $zoneName")),
      );
    }
  }

  Future<void> deleteZone(String zoneId) async {
    await ZoneService().deleteZone(zoneId);
    await fetchZones();
    ScaffoldMessenger.of(
      context as BuildContext,
    ).showSnackBar(SnackBar(content: Text("${zoneId} deleted successfully!")));
  }

  void searchZones(String query) {
    final results =
        zones.where((zone) {
          return zone.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
    filteredZones = results;
  }

  void _notify() {
    if (onZonesUpdated != null) {
      onZonesUpdated!(_zones);
    }
  }
}
