import 'user_model.dart';

class Admin extends User {
  Admin({
    required super.id,
    required super.name,
    required super.password,
    required super.role,
    //required super.contactInfo,
    required super.nationalId,
  });
}
