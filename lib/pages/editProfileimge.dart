import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:project/screen/myip.dart';

class EditProfileImage extends StatefulWidget {
  final String finalEmail;
  final String userId;
  final String profileImage;

  const EditProfileImage(
      {super.key,
      required this.finalEmail,
      required this.userId,
      required this.profileImage});

  @override
  _EditProfileImageState createState() => _EditProfileImageState();
}

class _EditProfileImageState extends State<EditProfileImage> {
  File? imageFile;

  Future<void> uploadImageProfile(File imageFile, String userId) async {
    try {
      String url = '${MyIp().domain}:3000/editimageprofile';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', imageFile.path),
      );
      request.fields['userId'] = userId;

      var res = await request.send();

      if (res.statusCode == 200) {
        final responseString = await res.stream.bytesToString();
        final data = jsonDecode(responseString);

        if (data['success'] == true) {
          Navigator.pop(context, true);
          Fluttertoast.showToast(msg: data['message']);
        } else {
          throw Exception('Failed to update profile image');
        }
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Failed to update profile image.");
    }
  }

  Future<void> deleteImageProfile() async {
    try {
      String uri = "${MyIp().domain}:3000/deleteimageprofile";
      var response = await http.post(Uri.parse(uri), body: {
        "id": widget.userId,
      });
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res["success"] == true) {
          Navigator.pop(context, true);
          Fluttertoast.showToast(msg: res['message']);
        } else {
          print("Update failed: ${res['message'] ?? 'Unknown error'}");
          Fluttertoast.showToast(
              msg: "Failed to delete image: ${res['message']}");
        }
      } else {
        print("Server returned an error: ${response.statusCode}");
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during update: $e");
      Fluttertoast.showToast(msg: "Error: $e");
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
        title: Text('Edit Profile Image'),
        actions: [
          TextButton(
            onPressed: () async {
              if (imageFile != null) {
                await uploadImageProfile(imageFile!, widget.userId);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.pink),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.pinkAccent,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!) as ImageProvider
                        : widget.profileImage.isNotEmpty
                            ? NetworkImage(
                                '${MyIp().domain}:3000/editimageprofile/${widget.profileImage}')
                            : null,
                    child: imageFile == null && widget.profileImage.isEmpty
                        ? Text(
                            widget.finalEmail.isNotEmpty
                                ? widget.finalEmail[0].toUpperCase()
                                : 'N/A',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          )
                        : null,
                  ),
                ),
                if (imageFile != null && widget.profileImage.isEmpty)
                  Positioned(
                    top: 25,
                    right: 25,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        deleteImagePick();
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.pink[300]),
                      ),
                      onPressed: pickImage,
                      icon: Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Gallery',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.pink[300]),
                      ),
                      onPressed: takePhoto,
                      icon: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Camera',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (widget.profileImage != null &&
                    widget.profileImage!.isNotEmpty)
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.pink[300]),
                    ),
                    onPressed: deleteImageProfile,
                    icon: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    label: Text(
                      'DeleteProfile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
