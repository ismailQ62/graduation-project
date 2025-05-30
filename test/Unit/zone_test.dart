import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/zone_model.dart';

void main() {
  group('Zone Model', () {
    /* test('Should create valid Zone object with default values', () {
      final zone = Zone(id: '1', name: 'Zone 1');

      expect(zone.id, '1');
      expect(zone.name, 'Zone 1');
      expect(zone.status, 'Disconnected');
      expect(zone.latitude, 0.0);
      expect(zone.longitude, 0.0);
    }) */
    ;

    test('Should convert Zone to Map correctly', () {
      final zone =
          Zone(id: '1', name: 'Zone 1')
            ..status = 'Active'
            ..latitude = 12.345
            ..longitude = 67.89;

      final map = zone.toMap();

      expect(map['id'], '1');
      expect(map['name'], 'Zone 1');
      expect(map['status'], 'Active');
      expect(map['latitude'], 12.345);
      expect(map['longitude'], 67.89);
    });
  });
}
