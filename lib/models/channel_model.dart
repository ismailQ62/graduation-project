class Channel {
  int? _id;
  String _name;

  Channel({int? id, required String name}) : _id = id, _name = name {
    if (name.isEmpty) {
      throw ArgumentError("Channel name cannot be empty");
    }
  }

  // Getters
  int? get id => _id;
  String get name => _name;

  // Setters
  set name(String value) {
    if (value.isEmpty) {
      throw ArgumentError("Channel name cannot be empty");
    }
    _name = value;
  }

  Map<String, dynamic> toMap() {
    return {'id': _id, 'name': _name};
  }

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(id: map['id'], name: map['name']);
  }
}
