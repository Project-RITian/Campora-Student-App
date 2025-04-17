import 'package:flutter/material.dart';

class User {
  final String email;
  final String name;
  final String department;
  final String className;
  final String year;

  User({
    required this.email,
    required this.name,
    required this.department,
    required this.className,
    required this.year,
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
      email: userData['email'],
      name: userData['name'],
      department: userData['department'],
      className: userData['class'],
      year: userData['year'],
    );
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
