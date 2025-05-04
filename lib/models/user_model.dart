class User {
  int? _id;
  String _name;
  //String last_name;
  String _nationalId;
  String _password;
  String _role;
  String? _connectedZoneId;

  User({
    int? id,
    required String name,
    required String nationalId,
    required String password,
    required String role,
    String? connectedZoneId,
  }) : _id = id,
       _name = name,
       _nationalId = nationalId,
       _password = password,
       _role = role,
       _connectedZoneId = connectedZoneId;

  int? get id => _id;
  String get name => _name;
  String get nationalId => _nationalId;
  String get password => _password;
  String get role => _role;
  String? get connectedZone => _connectedZoneId;

  set name(String value) {
    if (value.isEmpty || value.length < 3) {
      throw ArgumentError("Name must be at least 3 characters long");
    }
    _name = value;
  }

  set nationalId(String value) {
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      throw ArgumentError("National ID must be exactly 10 numeric digits");
    }
    _nationalId = value;
  }

  set password(String value) {
    if (value.length < 8) {
      throw ArgumentError("Password must be at least 8 characters");
    }
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~%^]).+$',
    ).hasMatch(value)) {
      throw ArgumentError(
        "Password must include uppercase, lowercase, a digit, and a special character",
      );
    }
    _password = value;
  }

  set role(String value) {
    if (!['Individual', 'Admin', 'Responder'].contains(value)) {
      throw ArgumentError("Invalid role selected");
    }
    _role = value;
  }

  set connectedZoneId(String? value) {
    if (value != null && value.isEmpty) {
      throw ArgumentError("Connected Zone ID cannot be empty");
    }
    _connectedZoneId = value;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'nationalId': _nationalId,
      'password': _password,
      'role': _role,
      'connectedZoneId': _connectedZoneId,
    };
  }

  static fromMap(Map<String, Object?> map) {}
}
