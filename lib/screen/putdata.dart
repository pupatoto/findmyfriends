import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/pages/home.dart';
import 'package:project/screen/addprofileimg.dart';
import 'package:project/screen/myip.dart';

class PutData extends StatefulWidget {
  final String email;
  const PutData({Key? key, required this.email}) : super(key: key);

  @override
  State<PutData> createState() => _PutDataState();
}

class _PutDataState extends State<PutData> {
  late TextEditingController dateOfBirthController;
  late TextEditingController ageController;
  String? selectedGender;
  int? age;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    dateOfBirthController = TextEditingController();
    ageController = TextEditingController();
  }

  @override
  void dispose() {
    dateOfBirthController.dispose();
    ageController.dispose();
    super.dispose();
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
        validateForm();
      });
    }
  }

  void validateForm() {
    setState(() {
      _isFormValid = dateOfBirthController.text.isNotEmpty &&
          ageController.text.isNotEmpty &&
          selectedGender != null;
    });
  }

  Future<void> Putdata() async {
    if (!_isFormValid) return;

    try {
      String uri = "${MyIp().domain}:3000/putdataprofile";
      var response = await http.post(Uri.parse(uri), body: {
        'email': widget.email,
        "birthdate": dateOfBirthController.text,
        "gender": selectedGender ?? '',
        "age": age.toString(),
      });

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res["success"] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => addProfileImg(
                      email: widget.email,
                    )),
          );
          Fluttertoast.showToast(msg: 'Updated successfully');
        } else {
          Fluttertoast.showToast(
            msg: 'Update failed: ${res['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error during update: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Putdata",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Container(
            margin: EdgeInsets.all(10),
            child: GestureDetector(
              onTap: () => selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
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
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), label: Text('Gender')),
              value: selectedGender,
              onChanged: (String? newValue) {
                setState(() {
                  selectedGender = newValue;
                  validateForm();
                });
              },
              items: ['Male', 'Female', 'LGBTQ']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              onPressed: _isFormValid ? Putdata : null,
              child: Text('Putdata', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
