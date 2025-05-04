import 'user_model.dart';

class Responder extends User {
  final String? credential;
  final bool verified;

  Responder({
    required super.id,
    required super.name,
    required super.nationalId,
    required super.password,
    required super.role,
    this.credential,
    this.verified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nationalId': nationalId,
      'password': password,
      'role': role,
      'credentialPath': credential,
      'verified': verified ? 1 : 0,
    };
  }

  factory Responder.fromMap(Map<String, dynamic> map) {
    return Responder(
      id: map['id'],
      name: map['name'],
      nationalId: map['nationalId'],
      password: map['password'],
      role: map['role'],
      credential: map['credential'],
      verified: (map['verified'] ?? 0) == 1,
    );
  }
}
