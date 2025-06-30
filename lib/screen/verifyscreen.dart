import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/home.dart';
import 'package:project/screen/myip.dart';
import 'package:flutter/services.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final formKey = GlobalKey<FormState>();
  TextEditingController otpController = TextEditingController();
  int resendToken = 0;
  bool isLoading = false;
  DateTime? otpSentTime;
  Timer? countdownTimer;
  int timeRemaining = 120;
  bool canResend = true;
  int cooldownTime = 120;
  Timer? cooldownTimerInstance;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void startCooldown() {
    setState(() {
      canResend = false;
    });

    cooldownTimerInstance = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (cooldownTime > 0) {
          cooldownTime--;
        } else {
          timer.cancel();
          canResend = true;
          cooldownTime = 90;
        }
      });
    });
  }

  Future<void> verifyOTP() async {
    try {
      var response = await http.post(
        Uri.parse('${MyIp().domain}:3000/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'otp': otpController.text,
        }),
      );

      if (timeRemaining <= 0) {
        Fluttertoast.showToast(msg: 'OTP has expired. Please resend OTP.');
        return;
      }

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'OTP verified successfully.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: 'Invalid OTP. Please try again.');
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'An error occurred. Please try again later.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resendOTP() async {
    if (!canResend) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${MyIp().domain}:3000/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'OTP has been resent.');
        otpSentTime = DateTime.now();
        setState(() {
          resendToken++;
          timeRemaining = 120;
          countdownTimer?.cancel();
          startTimer();
          startCooldown();
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'An error occurred. Please try again later.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    cooldownTimerInstance?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Email, ${widget.email}',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 245, 94, 83),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Colors.black, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: Card(
                color: Color.fromARGB(255, 249, 75, 75),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'A verification code has been sent to your email:',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          return null;
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  verifyOTP();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Verify OTP',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: canResend ? resendOTP : null,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                canResend
                                    ? 'Resend OTP (Requested $resendToken times)'
                                    : 'Please wait ${cooldownTime}s',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: 10),
                      Text(
                        'OTP expires in ${timeRemaining ~/ 60} minutes and ${timeRemaining % 60} seconds',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
