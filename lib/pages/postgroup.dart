// ignore_for_file: sort_child_properties_last, camel_case_types, prefer_const_constructors
import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/pages/map.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Post_Group extends StatefulWidget {
  const Post_Group({super.key});

  @override
  State<Post_Group> createState() => _Post_GroupState();
}

class _Post_GroupState extends State<Post_Group> {
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
  String? selectedProvince;

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

  Future<void> postGroup() async {
    try {
      String url = '${MyIp().domain}:3000/postgroup';

      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['email'] = finalEmail
        ..fields['group_name'] = groupname.text
        ..fields['type_group'] = type_group!
        ..fields['latitude'] = selectedLocation?.latitude.toString() ?? ''
        ..fields['longitude'] = selectedLocation?.longitude.toString() ?? ''
        ..fields['nameplace'] = selectedPlacename!
        ..fields['date'] = dateController.text
        ..fields['time'] = timeController.text
        ..fields['gender'] = selectedGenders.join(',')
        ..fields['age'] = '${rangeAge.start.round()}-${rangeAge.end.round()}'
        ..fields['maxParticipants'] = '$maxParticipants'
        ..fields['Province'] = '$selectedProvince';
      for (var imageFile in imagePath) {
        var pic = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(pic);
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var data = jsonDecode(responseData.body);

        if (data['success']) {
          Fluttertoast.showToast(msg: data['message']);
        } else {
          Fluttertoast.showToast(
              msg: data['message'] ?? 'Failed to create group');
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getShared() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final email = sharedPreferences.getString('email');

    if (email != null) {
      setState(() {
        finalEmail = email;
      });
      print("SharedPreferences Email: $finalEmail");
      print('Provinc $selectedProvince');
    } else {
      Fluttertoast.showToast(msg: "Email not found in SharedPreferences");
    }
  }

  Future<void> getData() async {
    await getShared();
  }

  ImagePicker imagePicker = ImagePicker();

  // ignore: non_constant_identifier_names
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
    setState(() {
      imagePath.removeAt(index);
    });
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

        selectedProvince = result['province'];
        print('Provinc $selectedProvince');
      });
    } else {
      Fluttertoast.showToast(msg: "No location selected.");
    }
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void validateAndSubmit() {
    if (groupname.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a group name");
      return;
    }
    if (type_group == null) {
      Fluttertoast.showToast(msg: "Please select a type");
      return;
    }
    if (locationController.text.isEmpty ||
        locationController.text == "Location not selected") {
      Fluttertoast.showToast(msg: "Please select a location");
      return;
    }
    if (dateController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a date");
      return;
    }
    if (timeController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a time");
      return;
    }
    if (selectedGenders.isEmpty) {
      Fluttertoast.showToast(msg: "Please select at least one gender");
      return;
    }
    if (imagePath.isEmpty) {
      Fluttertoast.showToast(msg: "Please select at least one image");
      return;
    }

    postGroup();
    Fluttertoast.showToast(msg: "Group created successfully");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavigationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          "Post Group",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        )),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //--NameGroup--
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

              ////select type
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
                    await getLocation();
                    setState(() {
                      locationController.text =
                          selectedPlacename ?? "Location not selected";
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedPlacename = value;
                    });
                  },
                ),
              ),
              // Calendar Picker
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
                      firstDate: DateTime(2012),
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
              //Time
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
              //Age
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age Range: ${rangeAge.start.round()} - ${rangeAge.end.round()} years',
                      style: TextStyle(fontSize: 16),
                    ),
                    RangeSlider(
                      values: rangeAge,
                      min: 15,
                      max: 100,
                      divisions: 82,
                      labels: RangeLabels(
                        rangeAge.start.round().toString(),
                        rangeAge.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          rangeAge = values;
                        });
                      },
                      activeColor: Colors.pink,
                      inactiveColor: Colors.pink.shade100,
                    ),
                  ],
                ),
              ),
              //gender
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Wrap(
                      spacing: 10,
                      children: genderOptions.keys.map((gender) {
                        return ChoiceChip(
                          label: Text(gender),
                          selected: genderOptions[gender] ?? false,
                          selectedColor: Colors.pink,
                          backgroundColor: Colors.grey[200],
                          onSelected: (isSelected) {
                            setState(() {
                              genderOptions[gender] = isSelected;
                              selectedGenders = genderOptions.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key)
                                  .toList();
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              //MaxParticipants
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
                      min: 1,
                      max: 100,
                      divisions: 99,
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
              Wrap(
                spacing: 8,
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
                              deleteImagePick(index);
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
              Padding(
                padding: EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => GetImg(),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.pink),
                  ),
                  child: Text(
                    "Select Image",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 50,
                  width: 200,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.pink)),
                    onPressed: () {
                      validateAndSubmit();
                    },
                    child: Text(
                      "Create Group",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          )),
        ));
  }
}
