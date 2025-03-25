class Message {
  int? _id;
  String _senderId;
  String _receiverId;
  String _content;
  String _timestamp;
  int _channelId;

  Message({
    int? id,
    required String senderId,
    required String receiverId,
    required String content,
    required String timestamp,
    required int channelId,
  }) : _id = id,
       _senderId = senderId,
       _receiverId = receiverId,
       _content = content,
       _timestamp = timestamp,
       _channelId = channelId {
    if (senderId.isEmpty) {
      throw ArgumentError("Sender ID cannot be empty");
    }
    if (receiverId.isEmpty) {
      throw ArgumentError("Receiver ID cannot be empty");
    }
    if (content.isEmpty) {
      throw ArgumentError("Message content must not be empty");
    }
  }

  // Getters
  int? get id => _id;
  String get senderId => _senderId;
  String get receiverId => _receiverId;
  String get content => _content;
  String get timestamp => _timestamp;
  int get channelId => _channelId;

  // Setters
  set content(String value) {
    if (value.isEmpty) {
      throw ArgumentError("Message content must not be empty");
    }
    _content = value;
  }

  set channelId(int value) {
    if (value <= 0) {
      throw ArgumentError("Invalid channel ID");
    }
    _channelId = value;
  }

  // Convert Message to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'senderId': _senderId,
      'receiverId': _receiverId,
      'content': _content,
      'timestamp': _timestamp,
      'channelId': _channelId,
    };
  }

  // Convert Map to Message
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      timestamp: map['timestamp'],
      channelId: map['channelId'],
    );
  }
}
