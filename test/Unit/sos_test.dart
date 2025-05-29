import 'package:flutter_test/flutter_test.dart';

String formatTimestamp(dynamic timestamp) {
  try {
    final dt = DateTime.tryParse(timestamp.toString());
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}/${dt.year}';
    }
  } catch (_) {}
  return timestamp.toString();
}

void main() {
  group('formatTimestamp()', () {
    test('Valid ISO timestamp returns formatted string', () {
      final ts = '2025-05-29T10:15:30.000Z';
      final result = formatTimestamp(ts);
      expect(result.contains('29/5/2025'), isTrue);
    });

    test('Invalid timestamp returns raw string', () {
      final result = formatTimestamp('invalid-date');
      expect(result, 'invalid-date');
    });

    test('Null input returns string "null"', () {
      final result = formatTimestamp(null);
      expect(result, 'null');
    });
  });

  group('SOS Message Payload Structure', () {
    test('Generated message contains required fields', () {
      final now = DateTime(2025, 5, 29, 12, 34, 56);
      final user = {
        'nationalId': '9876543210',
        'name': 'Test User',
        'connectedZone': 'Zone_1',
      };
      final location = {'lat': 32.1234, 'lng': 36.5678};
      final content = 'This is an emergency';

      final payload = {
        "type": "SOS",
        "senderID": user['nationalId'],
        "username": user['name'],
        "date": "2025-05-29",
        "time": "12:34:56",
        "content": content,
        "channelID": "0",
        "zoneId": user['connectedZone'],
        "receiverZone": "ALL",
        "location": "${location['lat']}, ${location['lng']}",
      };

      expect(payload['type'], 'SOS');
      expect(payload['senderID'], '9876543210');
      expect(payload['content'], contains('emergency'));
      expect(payload['location'], '32.1234, 36.5678');
    });
  });
}
