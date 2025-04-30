class AuthService {
  static String? _currentUserNationalId;

  static void setCurrentUserNationalId(String nationalId) {
    _currentUserNationalId = nationalId;
  }

  static String? getCurrentUserNationalId() {
    return _currentUserNationalId;
  }
}