import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CampusStatusProvider with ChangeNotifier {
  String _campusStatus = 'Checking...';
  static const double campusLat = 13.0389008; // Replace with actual campus latitude
  static const double campusLng = 80.0450698; // Replace with actual campus longitude
  static const double campusRadius = 500; // Radius in meters

  String get campusStatus => _campusStatus;

  Future<void> checkLocationAndUpdateStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _campusStatus = 'Location services disabled';
      notifyListeners();
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _campusStatus = 'Location permission denied';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _campusStatus = 'Location permission permanently denied';
      notifyListeners();
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance to campus
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusLat,
        campusLng,
      );

      // Update campus status
      _campusStatus = distance <= campusRadius ? 'In Campus' : 'Not in Campus';
      notifyListeners();
    } catch (e) {
      _campusStatus = 'Error fetching location';
      notifyListeners();
    }
  }
}
