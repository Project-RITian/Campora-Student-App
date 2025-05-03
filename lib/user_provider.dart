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

  // Add a method to convert User to a map (useful for Firestore or debugging)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'department': department,
      'class': className, // Match Firestore field name used in TimetableScreen
      'year': year,
      'regdNumber': regdNumber,
    };
  }

  // Factory method to create User from a map (e.g., Firestore data)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      department: map['department']?.toString() ?? '',
      className: map['class']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      regdNumber: map['regdNumber']?.toString() ?? '',
    );
  }
}

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  // Set user directly
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Set user from a JSON/map (e.g., from Firestore)
  void setUserFromJson(Map<String, dynamic> userData) {
    _user = User.fromMap(userData);
    notifyListeners();
  }

  // Update specific fields of the user (optional, for future use)
  void updateUser({
    String? email,
    String? name,
    String? department,
    String? className,
    String? year,
    String? regdNumber,
  }) {
    if (_user == null) return;
    _user = User(
      email: email ?? _user!.email,
      name: name ?? _user!.name,
      department: department ?? _user!.department,
      className: className ?? _user!.className,
      year: year ?? _user!.year,
      regdNumber: regdNumber ?? _user!.regdNumber,
    );
    notifyListeners();
  }

  // Clear user data (e.g., on logout)
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
