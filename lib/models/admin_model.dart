import 'user_model.dart';

class Admin extends User {
  Admin({
    required super.userID,
    required super.name,
    required super.password,
    required super.role,
    required super.contactInfo,
  });
}
