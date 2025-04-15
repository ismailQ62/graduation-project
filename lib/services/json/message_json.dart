import 'dart:convert';

class MessageJsonBuilder {
  static String build({
    required String senderId,
    required String receiverId,
    required String username,
    required String role,
    required String channelId,
    required String channelName,
    required String messageText,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    String type = "chat",
  }) {
    final message = {
      "type": type,
      "sender": senderId,
      "receiver": receiverId,
      "role": role,
      "channel_id": channelId,
      "channel_name": channelName,
      "username": username,
      "msg": messageText,
      "timestamp": timestamp.toUtc().toIso8601String(),
      "gps": {"lat": latitude, "lng": longitude},
    };

    return jsonEncode(message);
  }
}
