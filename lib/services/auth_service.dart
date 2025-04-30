import 'package:lorescue/models/user_model.dart';

class AuthService {
  static User? _currentUser;

static void setCurrentUser(User user) {
  _currentUser = user;
}

static User? getCurrentUser() {
  return _currentUser;
}
}