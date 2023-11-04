import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var locationManager = new Location();
  static const String initialLoctionId = "initialLocation";
  static const String UserLoctionId = "UserLocation";

  @override
  void initState() {
    super.initState();
    askUserForPermissionAndService();
  }

  void askUserForPermissionAndService() async {
    await requestPermission();
    await requestService();
    trackUserLocation();
  }

  var initialLocation = CameraPosition(
    target: LatLng(27.294093, 33.737521),
    zoom: 16,
  );
  GoogleMapController? _controller;
  Set<Marker> markersSet = {
    Marker(
      markerId: MarkerId(initialLoctionId),
      position: LatLng(27.294093, 33.737521),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Maps"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              markers: markersSet,
              mapType: MapType.normal,
              initialCameraPosition: initialLocation,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                drawUserMarker();
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              trackUserLocation();
            },
            child: Text("Start Tracking"),
          )
        ],
      ),
    );
  }

  void drawUserMarker() async {
    var canGetLocation = await canUseGPS();
    if (!canGetLocation) return;
    var locationData = await locationManager.getLocation();
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
        16));
    markersSet.add(Marker(
        markerId: MarkerId(UserLoctionId),
        position: LatLng(
            locationData.latitude ?? 0.0, locationData.longitude ?? 0.0)));
    setState(() {});
  }

  void getUserLocation() async {
    var canGetLocation = await canUseGPS();
    if (!canGetLocation) return;
    var locationData = await locationManager.getLocation();
    print(locationData.latitude);
    print(locationData.longitude);
  }

  StreamSubscription<LocationData>? trackingService = null;

  void trackUserLocation() async {
    var canGetLocation = await canUseGPS();
    if (!canGetLocation) return;
    locationManager.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      interval: 1000,
    );
    trackingService = locationManager.onLocationChanged.listen((locationData) {
      setState(() {
        markersSet.add(Marker(
            markerId: MarkerId(UserLoctionId),
            position: LatLng(
                locationData.latitude ?? 0.0, locationData.longitude ?? 0.0)));
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
            16));
      });
    });
  }

  @override
  void dispose() {
    trackingService?.cancel();
    super.dispose();
  }

  Future<bool> canUseGPS() async {
    var permissionGranted = await isPermissionGranted();
    if (!permissionGranted) {
      return false;
    }
    var isServiceEnabled = await isLoctionServiceEnabled();
    if (!isServiceEnabled) {
      return false;
    }
    return true;
  }

  Future<bool> isLoctionServiceEnabled() async {
    return await locationManager.serviceEnabled();
  }

  Future<bool> requestService() async {
    var enabled = await locationManager.requestService();
    return enabled;
  }

  Future<bool> isPermissionGranted() async {
    var permissionStatus = await locationManager.hasPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  Future<bool> requestPermission() async {
    var permissionStatus = await locationManager.requestPermission();
    return permissionStatus == PermissionStatus.granted;
  }
}
