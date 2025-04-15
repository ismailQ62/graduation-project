import 'dart:convert';

void main() {
  final jsonMessage = buildMessageJson(
    senderId: "user-157489",
    receiverId: "user-152880",
    username: "Ismail Qwasmi",
    role: "Individual",
    channelId: "channel-01",
    channelName: "Zone 1 - Main",
    messageText: "Testing JSON without emulator.",
    timestamp: DateTime.now(),
    latitude: 32.3936,
    longitude: 35.9865,
  );

  print("✅ Raw JSON:\n$jsonMessage");

  final prettyJson = const JsonEncoder.withIndent(
    '  ',
  ).convert(jsonDecode(jsonMessage));
  print("\n📦 Pretty JSON:\n$prettyJson");
}

String buildMessageJson({
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
