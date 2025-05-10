import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GPSService {
  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    print("Checking location services...");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return null;
    }
    print("Checking location permissions...");
    bool hasPermission = await _handlePermission();
    if (!hasPermission) return null;
    try {
      print("Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(Duration(seconds: 10));
      print("Got position: ${position.latitude}, ${position.longitude}");
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException catch (_) {
      print("Timed out while getting location.");
      return null;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }
}
