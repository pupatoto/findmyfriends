import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:permission_handler/permission_handler.dart';

const String apiKey = 'xxxxxxxxxxxxxxxx';

class PinMap extends StatefulWidget {
  const PinMap({super.key});

  @override
  State<PinMap> createState() => _PinMapState();
}

class _PinMapState extends State<PinMap> {
  LatLng defaultLocation = LatLng(13.75398, 100.50144);
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  late GooglePlace googlePlace;
  TextEditingController searchController = TextEditingController();
  List<AutocompletePrediction> predictions = [];
  LatLng? selectedPosition;
  String? selectedPlaceName;
  String? selectedProvince;

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(apiKey);
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted.");
    } else {
      print("Location permission denied.");
    }
  }

  Future<void> getProvince(LatLng position) async {
    var result = await googlePlace.search.getNearBySearch(
      Location(lat: position.latitude, lng: position.longitude),
      50,
      language: 'th',
    );
    if (result != null &&
        result.results != null &&
        result.results!.isNotEmpty) {
      String placeId = result.results!.first.placeId!;
      var details = await googlePlace.details.get(placeId, language: 'th');
      if (details != null && details.result != null) {
        for (var component in details.result!.addressComponents!) {
          if (component.types!.contains("administrative_area_level_1")) {
            setState(() {
              selectedProvince = component.longName;
            });
            break;
          }
        }
      }
    }
  }

  void addMarkerWithName(LatLng position, String placeName) async {
    final Marker marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: placeName),
      onTap: () {
        removeMarker(position);
      },
    );
    setState(() {
      markers.clear();
      markers.add(marker);
      selectedPosition = position;
      selectedPlaceName = placeName;
    });

    await getProvince(position);
  }

  void removeMarker(LatLng position) {
    setState(() {
      markers.removeWhere((marker) => marker.position == position);
    });
  }

  Future<void> searchLocation(String query) async {
    var result = await googlePlace.autocomplete
        .get(query, components: [Component("country", "th")]);
    if (result != null && result.predictions != null) {
      setState(() {
        predictions = result.predictions!;
      });
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  Future<void> selectLocation(String placeId) async {
    var details = await googlePlace.details.get(placeId);
    if (details != null && details.result != null) {
      var location = details.result!.geometry!.location;
      LatLng placeLocation = LatLng(location!.lat!, location.lng!);
      String placeName = details.result!.name ?? 'Unknown Place';

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(placeLocation, 15),
      );

      addMarkerWithName(placeLocation, placeName);

      setState(() {
        predictions = [];
        searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Location',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        searchLocation(searchController.text);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      searchLocation(value);
                    } else {
                      setState(() {
                        predictions = [];
                      });
                    }
                  },
                ),
                if (predictions.isNotEmpty)
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(predictions[index].description ?? ''),
                          onTap: () {
                            selectLocation(predictions[index].placeId!);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: defaultLocation,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: markers,
              myLocationEnabled: true,
              onTap: (LatLng position) {
                addMarkerWithName(position, 'Unknown Location');
              },
            ),
          ),
          if (selectedPosition != null && selectedPlaceName != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'latitude': selectedPosition!.latitude,
                        'longitude': selectedPosition!.longitude,
                        'placeName': selectedPlaceName,
                        'province': selectedProvince ??
                            'Unknown Province', // ส่งจังหวัดด้วย
                      });
                    },
                    child: Text(
                        'Confirm Location: $selectedPlaceName, Province: $selectedProvince'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
