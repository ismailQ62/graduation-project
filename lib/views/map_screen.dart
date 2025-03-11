import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //final MapController _mapController = MapController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Map')), body: content());
  }

  Widget content() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(32.55828, 35.87560),
        initialZoom: 15,
        minZoom: 0,
        maxZoom: 100,
        interactionOptions: const InteractionOptions(
          flags: ~InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        openStreetMapTileLater,
        /* CurrentLocationLayer(
          style: const LocationMarkerStyle(
            marker: DefaultLocationMarker(
              child: Icon(
                Icons.location_pin,
                color: Colors.white,
              )
            ),
            markerSize: Size(35, 35),
            markerDirection: MarkerDirection.heading,
          ),
        )*/
      ],
    );
  }
}

TileLayer get openStreetMapTileLater => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleatflet.flutter_map.example',
);
