import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import 'dart:math';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _driverPosition;
  double? _distance;

  @override
  void initState() {
    super.initState();
    Provider.of<LocationService>(context, listen: false).fetchStudentLocation();
  }

  void _updateDriverMarker(Map<dynamic, dynamic> data) {
    if (data.isEmpty) {
      setState(() {
        _markers.clear();
        _driverPosition = null;
      });
      return;
    }

    final driverId = data.keys.first;
    final locationData = data[driverId];
    final lat = locationData['latitude'] as double;
    final lng = locationData['longitude'] as double;
    final heading = locationData['heading']?.toDouble() ?? 0.0;

    setState(() {
      _driverPosition = LatLng(lat, lng);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(driverId),
          position: _driverPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: heading,
        ),
      );

      // Calculate distance to student
      final studentPos =
          Provider.of<LocationService>(context, listen: false).studentPosition;
      if (studentPos != null) {
        _distance = _calculateDistance(
          studentPos.latitude!,
          studentPos.longitude!,
          lat,
          lng,
        );
      }

      // Update camera position
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_driverPosition!),
      );
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth's radius in meters
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final deltaLat = (lat2 - lat1) * pi / 180;
    final deltaLon = (lon2 - lon1) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c / 1000; // Distance in kilometers
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-26.1929, 28.0308), // Wits University
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_driverPosition != null) {
                controller
                    .animateCamera(CameraUpdate.newLatLng(_driverPosition!));
              }
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: locationService.selectedBus,
                      hint: const Text('Select Bus'),
                      isExpanded: true,
                      items: locationService.buses
                          .map((bus) => DropdownMenuItem(
                                value: bus,
                                child: Text(bus),
                              ))
                          .toList(),
                      onChanged: (value) {
                        locationService.setSelectedBus(value);
                        if (value != null && value != 'Choose a bus') {
                          FirebaseDatabase.instance
                              .ref('locations/$value')
                              .onValue
                              .listen((event) {
                            final data =
                                event.snapshot.value as Map<dynamic, dynamic>?;
                            if (data != null) {
                              _updateDriverMarker(data);
                            } else {
                              _updateDriverMarker({});
                            }
                          });
                        } else {
                          setState(() {
                            _markers.clear();
                            _driverPosition = null;
                          });
                        }
                      },
                    ),
                    if (_driverPosition != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Distance to bus: ${_distance?.toStringAsFixed(2) ?? 'N/A'} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
