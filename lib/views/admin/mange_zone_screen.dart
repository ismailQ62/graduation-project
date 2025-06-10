import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/zone_controller.dart';
import 'package:lorescue/models/zone_model.dart';

class ManageZonesScreen extends StatefulWidget {
  const ManageZonesScreen({super.key});

  @override
  _ManageZonesScreenState createState() => _ManageZonesScreenState();
}

class _ManageZonesScreenState extends State<ManageZonesScreen> {
  TextEditingController searchController = TextEditingController();
  ZoneController zoneController = ZoneController();
  List<Zone> zones = []; 
  List<Zone> filteredZones = [];

  @override
  void initState() {
    super.initState();
    zoneController.init();
  }
  
  Future<void> fetchZones() async {
  await zoneController.fetchZones();
  setState(() {
    zoneController.onZonesUpdated!(zones);
    zoneController.onZonesUpdated!(filteredZones);
  });
}

  @override
  void dispose() {
    searchController.dispose();
    zoneController.dispose();
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
              onChanged: zoneController.searchZones,
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
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await zoneController.deleteZone(zone.name);
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
                          controller: searchController,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final zoneName = searchController.text.trim();
                              if(zoneName.isNotEmpty) {
                                await zoneController.addZone(zoneName);
                              }
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
