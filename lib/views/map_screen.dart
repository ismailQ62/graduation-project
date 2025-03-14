import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //final MapController _mapController = MapController();
  LatLng myCurrentLocation = const LatLng(32.4951,35.9912);
  late MapController mapController;
  Set<Marker> marker ={};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')), 
      body: content());
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
        _searchField(),
        CurrentLocationLayer(
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
        )
      ],
    );
    
  }
  Container _searchField() {
    return Container(
          margin: EdgeInsets.only(top: 20, left: 20, right: 20),
          child: TextField(
            decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xffF8F9FE),
                contentPadding: EdgeInsets.all(15),
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Color(0xff8F9098),
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: 
                  Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                )
              ),
          ),
        );
  }
}

TileLayer get openStreetMapTileLater => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleatflet.flutter_map.example',
);

