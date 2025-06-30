// ignore_for_file: sort_child_properties_last, camel_case_types, prefer_const_constructors
import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/map.dart';
import 'package:project/screen/myip.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Edit_Group extends StatefulWidget {
  final String groupCode; //
  const Edit_Group({super.key, required this.groupCode});

  @override
  State<Edit_Group> createState() => _Edit_GroupState();
}

class _Edit_GroupState extends State<Edit_Group> {
  String? type_group;
  var finalEmail;
  List<File> imagePath = [];
  LatLng? selectedLocation;
  String? selectedPlacename;
  TextEditingController groupname = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  RangeValues rangeAge = RangeValues(15, 35);
  List<String> selectedGenders = [];
  int maxParticipants = 10;
  List<String> image = [];
  List<String> imagesToDelete = [];
  int initialMaxParticipants = 10;
  String? selectedProvince;
  String? previousProvince;
  List<String> list = [
    "Sport",
    "Music",
    "Education",
    "Volunteer",
    "Event",
    'Food'
  ];

  Map<String, bool> genderOptions = {
    'Male': false,
    'Female': false,
    'LGBTQ': false,
  };

  Future<void> fetchGroupData() async {
    try {
      String url = '${MyIp().domain}:3000/getgroup';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"groupCode": widget.groupCode}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          if (data['success'] && data['userGroups'].isNotEmpty) {
            var groupData = data['userGroups'][0];
            groupname.text = groupData['group_name'];
            type_group = groupData['type_group'];

            selectedLocation = LatLng(
              double.tryParse(groupData['latitude'].toString()) ?? 0.0,
              double.tryParse(groupData['longitude'].toString()) ?? 0.0,
            );
            selectedPlacename = groupData['placename'];

            locationController.text = selectedPlacename ?? "Unknown Location";

            dateController.text = groupData['date'];
            timeController.text = groupData['time'];

            selectedProvince = groupData['province'];
            print('Province : $selectedProvince');
            maxParticipants =
                int.tryParse(groupData['max_participants'].toString()) ?? 1;
            if (maxParticipants < 1) maxParticipants = 1;
            initialMaxParticipants = maxParticipants;

            var ageParts = groupData['age'].split('-');
            if (ageParts.length == 2) {
              rangeAge = RangeValues(
                double.tryParse(ageParts[0]) ?? 0.0,
                double.tryParse(ageParts[1]) ?? 0.0,
              );
            }

            selectedGenders = groupData['gender'].split(',');
            for (String gender in selectedGenders) {
              genderOptions[gender] = true;
            }

            image = List<String>.from(groupData['image_path']);
          } else {
            Fluttertoast.showToast(msg: "No group data available");
          }
        });
      }
    } catch (e) {
      print("Error fetching group data: $e");
    }
  }

  Future<void> updateGroupData() async {
    try {
      String url = '${MyIp().domain}:3000/updategroup';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['groupCode'] = widget.groupCode;
      request.fields['group_name'] = groupname.text;
      request.fields['type_group'] = type_group ?? '';
      request.fields['latitude'] = selectedLocation?.latitude.toString() ?? '';
      request.fields['longitude'] =
          selectedLocation?.longitude.toString() ?? '';
      request.fields['placename'] = selectedPlacename ?? '';
      request.fields['date'] = dateController.text;
      request.fields['time'] = timeController.text;
      request.fields['age'] =
          "${rangeAge.start.round()}-${rangeAge.end.round()}";
      request.fields['gender'] = selectedGenders.join(',');
      request.fields['max_participants'] = maxParticipants.toString();
      request.fields['imagesToDelete'] = jsonEncode(imagesToDelete);
      request.fields['Province'] = selectedProvince ?? previousProvince ?? '';

      for (var img in imagePath) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', img.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        if (data['success']) {
          Fluttertoast.showToast(msg: "Group updated successfully");
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
              msg: "Failed to update group: ${data['message']}");
        }
      } else {
        Fluttertoast.showToast(msg: "Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating group data: $e");
      Fluttertoast.showToast(
          msg: "An error occurred while updating the group.");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGroupData();
  }

  ImagePicker imagePicker = ImagePicker();

  Future<void> GetImg() async {
    List<XFile>? selectedImages = await imagePicker.pickMultiImage();
    if (selectedImages != null) {
      setState(() {
        imagePath = selectedImages.map((img) => File(img.path)).toList();
      });
      print("Selected images: ${imagePath.length}");
    } else {
      Fluttertoast.showToast(msg: "No images selected");
    }
  }

  Future<void> deleteImagePick(int index) async {
    if (image.length > 1) {
      imagesToDelete.add(image[index]);

      setState(() {
        image.removeAt(index);
      });
    } else {
      Fluttertoast.showToast(
        msg: "At least one image must remain.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  Future<void> getLocation() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PinMap()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedLocation = LatLng(
          double.tryParse(result['latitude'].toString()) ?? 0.0,
          double.tryParse(result['longitude'].toString()) ?? 0.0,
        );
        selectedPlacename = result['placeName'];

        if (result['province'] != null) {
          previousProvince = selectedProvince;
          selectedProvince = result['province'];
          print('Updated Selected Province: $selectedProvince');
        } else {
          print('No new province selected, keeping: $selectedProvince');
        }
      });
    } else {
      Fluttertoast.showToast(msg: "No location selected.");
    }
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          "Edit Group",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        )),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Name Group
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: groupname,
                  decoration: InputDecoration(
                    label: Text('Group Name'),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
              ),
              // Select type
              Padding(
                padding: EdgeInsets.all(8.0),
                child: DropdownButtonFormField(
                  value: type_group,
                  hint: Text("Select type"),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      )),
                  items: list
                      .map((e) => DropdownMenuItem(
                            child: Text(e),
                            value: e,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      type_group = value;
                    });
                    print(type_group);
                  },
                ),
              ),
              // Location
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: locationController,
                  readOnly: false,
                  decoration: InputDecoration(
                    labelText: 'Pick a Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onTap: () async {
                    getLocation();
                    setState(() {
                      locationController.text =
                          selectedPlacename ?? "Location not selected";
                    });
                  },
                ),
              ),
              // Date Picker
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    label: Text('Select Date'),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: () async {
                    DateTime? pickDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickDate != null) {
                      String showDate =
                          "${pickDate.day}/${pickDate.month}/${pickDate.year}";
                      setState(() {
                        dateController.text = showDate;
                      });
                    }
                  },
                ),
              ),
              // Time Picker
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    label: Text('Select Time'),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  onTap: () async {
                    TimeOfDay? pickTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickTime != null) {
                      String showTime = pickTime.format(context);
                      setState(() {
                        timeController.text = showTime;
                      });
                    }
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Maximum Participants: $maxParticipants',
                      style: TextStyle(fontSize: 16),
                    ),
                    Slider(
                      value: maxParticipants.toDouble(),
                      min: initialMaxParticipants.toDouble(),
                      max: 100,
                      divisions: (100 - initialMaxParticipants).toInt(),
                      label: maxParticipants.round().toString(),
                      activeColor: Colors.pink,
                      inactiveColor: Colors.pink.shade100,
                      onChanged: (double value) {
                        setState(() {
                          maxParticipants = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Image Picker
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Images:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(image.length, (index) {
                        print(
                            '${MyIp().domain}:3000/postgroup/${image[index]}');
                        return Stack(
                          children: [
                            Image.network(
                              '${MyIp().domain}:3000/postgroup/${image[index]}',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  deleteImagePick(index);
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // Image Upload Section
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Upload New Images:'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(imagePath.length, (index) {
                        return Stack(
                          children: [
                            Image.file(
                              imagePath[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    imagePath.removeAt(index);
                                  });
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 12,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: GetImg,
                      child: Text('Select Images'),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    updateGroupData();
                  },
                  child: Text('Edit Group'),
                ),
              ),
            ],
          )),
        ));
  }
}
