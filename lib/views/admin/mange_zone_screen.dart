import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lorescue/services/database/zone_service.dart'; // ZoneService for database operations
import 'package:lorescue/models/zone_model.dart'; // Zone model for data representation

class ManageZonesScreen extends StatefulWidget {
  const ManageZonesScreen({super.key});

  @override
  _ManageZonesScreenState createState() => _ManageZonesScreenState();
}

class _ManageZonesScreenState extends State<ManageZonesScreen> {
  List<Zone> zones = [];
  List<Zone> filteredZones = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchZones();
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
      final newZone = Zone(id: DateTime.now().toString(), name: zoneName);
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
                            subtitle: Text('ID: ${zone.id}'),
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
