import 'user_model.dart';

class Individual extends User {
  Individual({
    required super.id,
    required super.name,
    required super.password,
    required super.role,
    //required super.contactInfo,
    required super.nationalId,
  });
}
