class User {
  final String userID;
  String name;
  String password;
  String role;
  //Coordinates location;
  String contactInfo;

  User({
    required this.userID,
    required this.name,
    required this.password,
    required this.role,
    // required this.location,
    required this.contactInfo,
  });

  // Getters
  String getUserID() => userID;
  String getUserName() => name;
  String getUserPassword() => password;
  String getUserRole() => role;
  // Coordinates getUserLocation() => location;
  String getUserContactInfo() => contactInfo;

  // Setters
  void setUserName(String newName) => name = newName;
  void setUserPassword(String newPassword) => password = newPassword;
  void setUserRole(String newRole) => role = newRole;
  //void setUserLocation(Coordinates newLocation) => location = newLocation;
  void setUserContactInfo(String newContactInfo) =>
      contactInfo = newContactInfo;

  // Convert User to Map (for Database sqlite)
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'password': password,
      'role': role,
      //  'location': location.toMap(),
      'contactInfo': contactInfo,
    };
  }
}
