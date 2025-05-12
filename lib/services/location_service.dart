import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationService with ChangeNotifier {
  String? _selectedBus;
  LocationData? _studentPosition;
  Location location = Location();

  String? get selectedBus => _selectedBus;
  LocationData? get studentPosition => _studentPosition;

  final List<String> buses = [
    'Choose a bus',
    'Circuit Bus All-Res',
    'Circuit Bus Reverse',
    'R22',
    'NSW -> AMH -> WEC',
    'WJ -> WEC -> MAIN',
    'MAIN -> NSW -> WEC',
    'NSW -> AMH -> WEC -> MAIN',
    'EOH -> KNK -> MAIN',
  ];

  void setSelectedBus(String? bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  Future<void> fetchStudentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _studentPosition = await location.getLocation();
    notifyListeners();

    location.onLocationChanged.listen((LocationData currentLocation) {
      _studentPosition = currentLocation;
      notifyListeners();
    });
  }
}
