// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:project/Adminpage/admin_page.dart';
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/pages/resetpass.dart';
import 'package:project/screen/myip.dart';
import 'package:project/screen/putdata.dart';
import 'package:project/screen/register.dart';
import 'package:project/screen/verifyscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool showverify = false;
  bool showPassword = false;
  Future<void> Signin() async {
    try {
      String url = '${MyIp().domain}:3000/login';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.text,
          'password': password.text,
        }),
      );

      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response['success']) {
          await User.setsignin(true);
          Fluttertoast.showToast(msg: response['message']);

          if (response['isAdmin']) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminPage()),
            );
          } else {
            // Check the putData status
            if (response['putData'] == false) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => PutData(
                          email: email.text,
                        )),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const BottomNavigationPage()),
              );
            }
          }
        } else {
          Fluttertoast.showToast(msg: response['message']);
        }
      } else {
        var response = jsonDecode(res.body);
        if (response['verify'] == false) {
          setState(() {
            showverify = true;
          });
        }
        Fluttertoast.showToast(
            msg: response['message'] ?? "Server Error: ${res.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  Future<void> sendOtp() async {
    try {
      String url = '${MyIp().domain}:3000/sendotp';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.text,
        }),
      );

      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        Fluttertoast.showToast(msg: response['message']);
      } else {
        var response = jsonDecode(res.body);
        Fluttertoast.showToast(
            msg: response['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred while sending OTP.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 19, 19, 1),
      body: Center(
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Welcome !',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'To continue using this app',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    'Please sign in first.',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 30),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(errorText: 'Please Input Your Email'),
                        EmailValidator(errorText: 'Email format is invalid.')
                      ]),
                      controller: email,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),
                      validator: RequiredValidator(
                          errorText: 'Please Input Your password'),
                      controller: password,
                    ),
                  ),
                  if (showverify)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VerifyEmailScreen(
                                      email: email.text,
                                    )));
                        sendOtp();
                      },
                      child: const Text(
                        'Please Verify Your Email Here!',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Resetpass(
                                  email: email.text ?? '',
                                )),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.pink,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 240, 94, 83),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final SharedPreferences preferences =
                              await SharedPreferences.getInstance();
                          preferences.setString('email', email.text);
                          Signin();
                          setState(() {});
                        }
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle:
                          const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterScreen()));
                    },
                    child: const Text(
                      "Didn't have any Account? Sign Up now",
                      style: TextStyle(color: Colors.pink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
