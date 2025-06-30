import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/screen/myip.dart';

class edit_profile extends StatefulWidget {
  final String userid;
  final String username;
  final String finalEmail;
  final String birthdate;
  final String gender;
  final String age;

  edit_profile(this.userid, this.username, this.finalEmail, this.birthdate,
      this.gender, this.age);

  @override
  State<edit_profile> createState() => _edit_profileState();
}

class _edit_profileState extends State<edit_profile> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController idController;
  late TextEditingController dateOfBirthController;
  late TextEditingController ageController;
  String? selectedGender;
  int? age;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    emailController = TextEditingController(text: widget.finalEmail);
    idController = TextEditingController(text: widget.userid);
    dateOfBirthController = TextEditingController(text: widget.birthdate);
    selectedGender = getInitialGender(widget.gender);
    age = calculateAge(widget.birthdate);
    ageController = TextEditingController(text: age?.toString() ?? '');
  }

  String? getInitialGender(String gender) {
    String normalizedGender = gender.trim().toLowerCase();
    if (normalizedGender == 'male') {
      return 'Male';
    } else if (normalizedGender == 'female') {
      return 'Female';
    } else {
      return 'LGBTQ';
    }
  }

  int? calculateAge(String birthdate) {
    try {
      List<String> parts = birthdate.split('-');
      DateTime birthDate = DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));

      DateTime now = DateTime.now();
      int calculatedAge = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        calculatedAge--;
      }
      return calculatedAge;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateOfBirthController.text = DateFormat('dd-MM-yyyy').format(picked);
        age = calculateAge(dateOfBirthController.text);
        ageController.text = age?.toString() ?? '';
      });
    }
  }

  Future<void> updateRecord() async {
    try {
      String uri = "${MyIp().domain}:3000/editprofile";
      var response = await http.post(Uri.parse(uri), body: {
        "username": usernameController.text,
        "email": emailController.text,
        "id": idController.text,
        "birthdate": dateOfBirthController.text,
        "gender": selectedGender ?? '',
        "age": age.toString(),
      });

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res["success"] == true) {
          Fluttertoast.showToast(msg: 'Updated successfully');
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => BottomNavigationPage()));
        } else {
          Fluttertoast.showToast(
              msg: 'Update failed: ${res['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 409) {
        Fluttertoast.showToast(msg: 'Username is already used');
      } else {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error during update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        foregroundColor: Colors.pink,
      ),
      body: Column(children: [
        SizedBox(height: 50),
        Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
            readOnly: true,
            controller: idController,
            decoration: InputDecoration(
                border: OutlineInputBorder(), label: Text('Your ID')),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
            readOnly: true,
            controller: emailController,
            decoration: InputDecoration(
                border: OutlineInputBorder(), label: Text('Your Email')),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
                border: OutlineInputBorder(), label: Text('Enter the Name')),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: GestureDetector(
            child: AbsorbPointer(
              child: TextFormField(
                readOnly: true,
                controller: dateOfBirthController,
                decoration: InputDecoration(
                  label: Text('Birth Date'),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
            readOnly: true,
            controller: ageController,
            decoration: InputDecoration(
                border: OutlineInputBorder(), label: Text('Age')),
          ),
        ),
        // Gender Dropdown
        Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
            readOnly: true,
            controller: TextEditingController(text: selectedGender),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text('Gender'),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              updateRecord();
            },
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: TextButton(
            child: Text("Go Back", style: TextStyle(color: Colors.pink)),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BottomNavigationPage()));
            },
          ),
        )
      ]),
    );
  }
}
