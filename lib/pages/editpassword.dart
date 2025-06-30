import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'dart:convert';

import 'package:project/screen/myip.dart';

class Editpassword extends StatefulWidget {
  final String email;
  const Editpassword({required this.email, super.key});

  @override
  State<Editpassword> createState() => _EditpasswordState();
}

class _EditpasswordState extends State<Editpassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController oldPasswordController = TextEditingController();

  Future<void> checkOldPassword() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('${MyIp().domain}:3000/isoldpassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'password': oldPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isValid']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPassword(email: widget.email),
            ),
          );
        } else {
          Fluttertoast.showToast(
              msg: 'Incorrect old password. Please try again.');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Error checking password. Please try again later.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Old Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  checkOldPassword();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.pink, // ตั้งค่าสีข้อความเป็นสีขาว
                ),
                child: const Text('Enter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPassword extends StatefulWidget {
  final String email;
  const ResetPassword({required this.email, super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> updatePassword() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('${MyIp().domain}:3000/updatepassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'password': newPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Password updated successfully.');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavigationPage()),
        );
      } else {
        Fluttertoast.showToast(
            msg: 'Error updating password. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  updatePassword();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.pink,
                ),
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
