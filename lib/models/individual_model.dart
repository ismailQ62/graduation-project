import 'user_model.dart';

class Individual extends User {
  Individual({
    required super.userID,
    required super.name,
    required super.password,
    required super.role,
    required super.contactInfo,
  });
}
