import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;

class MapDetail extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String placeName;
  final String? email;
  final String groupstatus;
  final String joinStatus;
  final String statusMessage;
  final String grouCode;

  const MapDetail({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.email,
    required this.groupstatus,
    required this.joinStatus,
    required this.statusMessage,
    required this.grouCode,
  }) : super(key: key);

  @override
  State<MapDetail> createState() => _MapDetailState();
}

class _MapDetailState extends State<MapDetail> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Circle> circles = {};
  bool canCheckIn = false;

  @override
  void initState() {
    super.initState();

    markers.add(
      Marker(
        markerId: MarkerId('selected_location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(title: widget.placeName),
      ),
    );

    circles.add(
      Circle(
        circleId: CircleId('selected_circle'),
        center: LatLng(widget.latitude, widget.longitude),
        radius: 500, // Radius of 500 meters
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );

    checkUserLocation();
  }

  Future<void> checkUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        canCheckIn = inRadius(
          position.latitude,
          position.longitude,
          widget.latitude,
          widget.longitude,
          500, // 500 meters
        );
      });
    }
  }

  bool inRadius(double userLat, double userLng, double targetLat,
      double targetLng, double radius) {
    const double earthRadius = 6371000;
    double dLat = toRadians(targetLat - userLat);
    double dLng = toRadians(targetLng - userLng);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(toRadians(userLat)) *
            cos(toRadians(targetLat)) *
            sin(dLng / 2) *
            sin(dLng / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance <= radius;
  }

  double toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<void> checkin() async {
    try {
      String url = '${MyIp().domain}:3000/checkin';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'groupCode': widget.grouCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: data['message']);
        print("Response body: ${res.body}");
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.joinStatus == '1'
              ? 'You already checked in'
              : (widget.joinStatus == '0' && widget.groupstatus == '1')
                  ? 'Time Out'
                  : 'Not checked in',
          style:
              const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: markers,
              circles: circles,
              myLocationEnabled: true,
            ),
          )
        ],
      ),
    );
  }
}
