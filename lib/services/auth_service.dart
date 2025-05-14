import 'package:lorescue/models/user_model.dart';

class AuthService {
  static User? _currentUser;

  static User? getCurrentUser() => _currentUser;

  static void setCurrentUser(User user) {
    _currentUser = user;
  }

  static void logout() {
    _currentUser = null;
  }
}
