class Zone {
  String id;
  String name;

  Zone({required this.id, required this.name});
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(id: map['id'], name: map['name']);
  }
}
