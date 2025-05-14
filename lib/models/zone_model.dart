class Zone {
  String id;
  String name;
  String status = 'Disconnected';
  String latitude = '0';
  String longitude = '0';

  Zone({required this.id, required this.name, status, latitude, longitude});
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'status': status, 'latitude': latitude, 'longitude': longitude};
  }

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(id: map['id'], name: map['name'], status: map['status'], latitude: map['latitude'], longitude: map['longitude']);
  }
}
