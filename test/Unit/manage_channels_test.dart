import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/channel_model.dart';

void main() {
  group('Manage Channels Logic', () {
    List<Channel> channels = [];

    setUp(() {
      channels = [
        Channel(id: 1, name: 'Main', type: 'main'),
        Channel(id: 2, name: 'News', type: 'news'),
      ];
    });

    test('NewChannel WebSocket adds if not exists', () {
      final incoming = {
        'type': 'NewChannel',
        'name': 'Chat',
        'channelType': 'chat',
      };

      final exists = channels.any((c) => c.name == incoming['name']);
      if (!exists) {
        channels.add(
          Channel(name: incoming['name']!, type: incoming['channelType']!),
        );
      }

      expect(channels.any((c) => c.name == 'Chat'), isTrue);
    });

    test('NewChannel WebSocket does NOT add duplicates', () {
      final incoming = {
        'type': 'NewChannel',
        'name': 'Main',
        'channelType': 'main',
      };

      final exists = channels.any((c) => c.name == incoming['name']);
      if (!exists) {
        channels.add(
          Channel(name: incoming['name']!, type: incoming['channelType']!),
        );
      }

      final count = channels.where((c) => c.name == 'Main').length;
      expect(count, 1);
    });

    test('Search filters correctly', () {
      final query = 'news';
      final results =
          channels
              .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

      expect(results.length, 1);
      expect(results.first.name, equals('News'));
    });

    test('Delete channel removes it from list', () {
      final nameToDelete = 'Main';
      channels.removeWhere((c) => c.name == nameToDelete);
      expect(channels.any((c) => c.name == nameToDelete), isFalse);
    });
  });
}
