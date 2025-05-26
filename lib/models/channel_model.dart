class Channel {
  int? _id;
  String _name;
  String _type;

  Channel({int? id, required String name, required String type})
    : _id = id,
      _name = name,
      _type = type {
    if (name.isEmpty) throw ArgumentError("Channel name cannot be empty");
    if (type.isEmpty) throw ArgumentError("Channel type cannot be empty");
  }

  int? get id => _id;
  String get name => _name;
  String get type => _type;

  set name(String value) {
    if (value.isEmpty) throw ArgumentError("Channel name cannot be empty");
    _name = value;
  }

  set type(String value) {
    if (value.isEmpty) throw ArgumentError("Channel type cannot be empty");
    _type = value;
  }

  Map<String, dynamic> toMap() {
    return {'id': _id, 'name': _name, 'type': _type};
  }

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(id: map['id'], name: map['name'], type: map['type']);
  }
}
