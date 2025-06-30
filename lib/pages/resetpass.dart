import 'dart:async';
import 'dart:convert';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/screen/myip.dart';

class Resetpass extends StatefulWidget {
  final String email;
  const Resetpass({
    super.key,
    required this.email,
  });

  @override
  State<Resetpass> createState() => _ResetpassState();
}

class _ResetpassState extends State<Resetpass> {
  final formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool isOtpSent = false;
  bool isObscure = true;
  Timer? otpTimer;
  int otpCountdown = 60;

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.email);
  }

  Future<void> sendOtp() async {
    setState(() {
      isLoading = true;
    });

    try {
      String url = '${MyIp().domain}:3000/send-otp-reset';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.text}),
      );

      var response = jsonDecode(res.body);

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'OTP sent to your email.');
        setState(() {
          isOtpSent = true;
          startOtpCountdown();
        });
      } else {
        Fluttertoast.showToast(
            msg: response['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startOtpCountdown() {
    otpCountdown = 120;
    otpTimer?.cancel();

    otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (otpCountdown > 0) {
        setState(() {
          otpCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isOtpSent = false;
          otpController.clear();
        });
        Fluttertoast.showToast(
            msg: 'OTP has expired, please request a new one.');
      }
    });
  }

  Future<void> resetPassword() async {
    setState(() {
      isLoading = false;
    });

    try {
      String url = '${MyIp().domain}:3000/verify-otp-reset';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.text,
          'otp': otpController.text,
          'newPassword': newPasswordController.text,
        }),
      );

      var response = jsonDecode(res.body);

      if (response['success'] == true) {
        Fluttertoast.showToast(msg: 'Password reset successful.');
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
            msg: response['message'] ?? 'Failed to reset password.');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    otpTimer?.cancel();
    email.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(19, 19, 19, 1),
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(19, 19, 19, 1),
        iconTheme: const IconThemeData(
          color: Colors.pink,
        ),
      ),
      body: Center(
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.all(20),
            children: [
              TextFormField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: MultiValidator([
                  RequiredValidator(errorText: 'Please input your email'),
                  EmailValidator(errorText: 'Invalid email format'),
                ]),
                controller: email,
              ),
              SizedBox(height: 20),
              if (isOtpSent) ...[
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'OTP',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  validator:
                      RequiredValidator(errorText: 'Please input the OTP'),
                  controller: otpController,
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure;
                        });
                      },
                    ),
                  ),
                  validator: RequiredValidator(
                      errorText: 'Please input a new password'),
                  controller: newPasswordController,
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  controller: confirmPasswordController,
                ),
                SizedBox(height: 20),
                Text(
                  'OTP expires in: $otpCountdown seconds',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                width: 350,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 240, 72, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            if (isOtpSent) {
                              await resetPassword();
                            } else {
                              await sendOtp();
                            }
                          }
                        },
                  child: Text(
                    isOtpSent ? 'Reset Password' : 'Send OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
