class Message {
  int? _id;
  String _senderId;
  String _receiverId;
  String _content;
  String _timestamp;
  /* bool _isRead; */

  Message({
    int? id,
    required String senderId,
    required String receiverId,
    required String content,
    required String timestamp,
    /* bool isRead = false, */
  }) : _id = id,
       _senderId = senderId,
       _receiverId = receiverId,
       _content = content,
       _timestamp = timestamp
  /* _isRead = isRead */ {
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

  int? get id => _id;
  String get senderId => _senderId;
  String get receiverId => _receiverId;
  String get content => _content;
  String get timestamp => _timestamp;
  /*  bool get isRead => _isRead; */

  set content(String value) {
    if (value.isEmpty) {
      throw ArgumentError("Message content must not be empty");
    }
    _content = value;
  }

  /* set isRead(bool value) {
    _isRead = value;
  } */

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'senderId': _senderId,
      'receiverId': _receiverId,
      'content': _content,
      'timestamp': _timestamp,
      /* 'isRead': _isRead ? 1 : 0, */
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      timestamp: map['timestamp'],
      /* isRead: map['isRead'] == 1, */
    );
  }
}
