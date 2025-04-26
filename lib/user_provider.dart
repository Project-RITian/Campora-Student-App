import 'package:flutter/material.dart';

class User {
  final String email;
  final String name;
  final String department;
  final String className;
  final String year;
  final String regdNumber;

  User({
    required this.email,
    required this.name,
    required this.department,
    required this.className,
    required this.year,
    required this.regdNumber,
  });
}

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void setUserFromJson(Map<String, dynamic> userData) {
    _user = User(
      email: userData['email']?.toString() ?? '',
      name: userData['name']?.toString() ?? 'Unknown',
      department: userData['department']?.toString() ?? '',
      className: userData['class']?.toString() ?? '',
      year: userData['year']?.toString() ?? '',
      regdNumber: userData['regdNumber']?.toString() ?? '',
    );
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
