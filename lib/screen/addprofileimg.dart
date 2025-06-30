import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/screen/myip.dart';

class addProfileImg extends StatefulWidget {
  final String email;
  const addProfileImg({super.key, required this.email});

  @override
  State<addProfileImg> createState() => _addProfileImgState();
}

class _addProfileImgState extends State<addProfileImg> {
  File? imageFile;

  Future<void> uploadImageProfile(File imageFile) async {
    if (imageFile == null) {
      Fluttertoast.showToast(msg: "Please select an image first.");
      return;
    }

    try {
      String url = '${MyIp().domain}:3000/addprofileimage';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', imageFile.path),
      );
      request.fields['email'] = widget.email;

      var res = await request.send();

      if (res.statusCode == 200) {
        final responseString = await res.stream.bytesToString();
        final data = jsonDecode(responseString);

        if (data['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigationPage()),
          );
          Fluttertoast.showToast(msg: data['message']);
        } else {
          Fluttertoast.showToast(msg: 'Failed to update profile image');
        }
      } else {
        Fluttertoast.showToast(msg: 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Failed to update profile image.");
    }
  }

  Future<void> deleteImagePick() async {
    setState(() {
      imageFile = null;
    });
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> takePhoto() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile Image',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              uploadImageProfile(imageFile!);
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.pinkAccent,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!) as ImageProvider
                        : null,
                    child: imageFile == null
                        ? Text(
                            widget.email[0].toUpperCase(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                if (imageFile != null)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: deleteImagePick,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                ),
                onPressed: pickImage,
                icon: Icon(Icons.photo_library, color: Colors.white),
                label: Text('Gallery', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                ),
                onPressed: takePhoto,
                icon: Icon(Icons.camera_alt, color: Colors.white),
                label: Text('Camera', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 150),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BottomNavigationPage()),
                );
              },
              child: Text(
                'Skip',
                style: TextStyle(
                    color: Colors.pink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
