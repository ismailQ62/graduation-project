import 'dart:async';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class ZoneService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Zone>> getAllZones() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('zones');

    return List.generate(maps.length, (i) {
      return Zone(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        status: maps[i]['status'] as String,
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
      );
    });
  }

  Future<bool> addZone(Zone zone) async {
    final db = await _dbService.database;
    final existingZone = await ZoneService().getAllZones();
    if (!existingZone.any((z) => z.name == zone.name)) {
      await db.insert(
        'zones',
        zone.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }
    return false;
  }

  Future<void> deleteZone(String zoneId) async {
    final db = await _dbService.database;
    await db.delete('zones', where: 'id = ?', whereArgs: [zoneId]);
  }

  Future<void> updateZone(String zoneName, String status, double lat, double lng) async {
    final db = await _dbService.database;
    await db.update(
      'zones',
      {'status': status,
       'latitude': lat,
       'longitude': lng,},
      where: 'name = ?',
      whereArgs: [zoneName],
    );
  }
}
