class Zone {
  String id;
  String name;
  String status = 'Checking...';
  double latitude = 0.0;
  double longitude = 0.0;
  bool notifiedDisconnected;

  Zone({required this.id, required this.name, status, latitude, longitude, this.notifiedDisconnected = false}) {
    this.status = status ?? 'Checking...';
    this.latitude = latitude ?? 0.0;
    this.longitude = longitude ?? 0.0;
  }
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'status': status, 'latitude': latitude, 'longitude': longitude,
            'notifiedDisconnected': notifiedDisconnected};
  }

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(id: map['id'], name: map['name'], status: map['status'], latitude: map['latitude'], longitude: map['longitude']);
  }
}
