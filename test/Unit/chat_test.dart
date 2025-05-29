import 'package:flutter_test/flutter_test.dart';
//import 'package:intl/intl.dart';

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
    test('formats valid ISO date', () {
      final isoDate = '2024-05-29T14:30:45.123Z';
      // final expected = '14:30, 29/5/2024'; // depending on UTC vs local
      final result = formatTimestamp(isoDate);
      expect(result.contains('29/5/2024'), isTrue);
    });

    test('returns raw string on invalid input', () {
      final input = 'invalid-date';
      final result = formatTimestamp(input);
      expect(result, equals('invalid-date'));
    });

    test('handles null safely', () {
      final result = formatTimestamp(null);
      expect(result, equals('null'));
    });
  });

  group('messageType', () {
    test('channel type lowercased becomes messageType', () {
      final type = 'Chat';
      final messageType = type.toLowerCase();
      expect(messageType, equals('chat'));
    });
  });

  group('send message payload logic', () {
    test('creates valid message payload structure', () {
      //final now = DateTime(2024, 5, 29, 15, 45, 10);
      final nationalId = '1234567890';
      final username = 'Ismail';
      final channelId = 1;
      final zoneId = 'Zone_1';
      final content = 'Hello!';
      final receiverZone = 'Zone_2';

      final message = {
        "type": "Chat",
        "senderID": nationalId,
        "username": username,
        "date": "2024-05-29",
        "time": "15:45:10",
        "content": content,
        "channelID": channelId.toString(),
        "zoneId": zoneId,
        "receiverZone": receiverZone,
        "receiverId": '',
        "location": "32.1234,36.5678",
      };

      expect(message['type'], 'Chat');
      expect(message['senderID'], nationalId);
      expect(message['content'], 'Hello!');
      expect(message['receiverZone'], receiverZone);
    });
  });
}
