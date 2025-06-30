// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/screen/login.dart';
import 'package:project/screen/myip.dart';
import 'package:project/screen/verifyscreen.dart';
import '../pages/user.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController confirmpassword = TextEditingController();
  bool isAccept = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  Future<void> Register() async {
    try {
      String url = '${MyIp().domain}:3000/register';

      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.text,
          'password': password.text,
          'username': username.text,
        }),
      );

      var response = jsonDecode(res.body);

      if (response['success'] == true) {
        await User.setsignin(true);
        Fluttertoast.showToast(msg: response['message']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(email: email.text),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: response['message']);
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 19, 19, 1),
      body: Center(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please complete your',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const Text(
                    'biodata correctly',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: username,
                      style: TextStyle(color: Colors.white),
                      obscureText: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(errorText: 'Please Input Your Name'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: email,
                      style: TextStyle(color: Colors.white),
                      obscureText: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 3)),
                        labelText: 'Your E-Mail',
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(errorText: 'Please Input Your Email'),
                        EmailValidator(errorText: 'Email format is invalid.')
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: password,
                      style: TextStyle(color: Colors.white),
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Create your Password',
                        prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(
                            errorText: 'Please Input Your password'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: confirmpassword,
                      style: TextStyle(color: Colors.white),
                      obscureText: !confirmPasswordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Re-Type your Password',
                        prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              confirmPasswordVisible =
                                  !confirmPasswordVisible; // สลับการแสดงรหัสผ่านยืนยัน
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Confirm your password';
                        } else if (value != password.text) {
                          return 'Passwords don\'t match!';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 240, 94, 83),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (password.text.length < 6) {
                            String messageError =
                                'The password must be at least 7 characters long.';
                            Fluttertoast.showToast(msg: messageError);
                          } else if (!isAccept) {
                            Fluttertoast.showToast(
                                msg: 'Please accept conditions.');
                          } else {
                            Register();
                          }
                        }
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isAccept,
                        onChanged: (value) {
                          setState(() {
                            isAccept = value!;
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Consent and Conditions'),
                                content: SingleChildScrollView(
                                    child: SingleChildScrollView(
                                  child: Text(
                                    '1. การเก็บรวบรวมข้อมูลส่วนบุคคล\n'
                                    'เราจะเก็บข้อมูลส่วนบุคคลของท่านเท่าที่จำเป็นและเหมาะสม เช่น ชื่อ นามสกุล ที่อยู่ อีเมล หมายเลขโทรศัพท์ หรือข้อมูลที่สามารถระบุตัวบุคคลได้อื่นๆ\n'
                                    'การเก็บข้อมูลนี้เกิดขึ้นเมื่อท่านทำการลงทะเบียน ใช้บริการ สอบถามข้อมูล หรือทำธุรกรรมผ่านทางเว็บไซต์หรือแอปพลิเคชันของเรา\n\n'
                                    '2. วัตถุประสงค์ในการใช้ข้อมูล\n'
                                    'ข้อมูลส่วนบุคคลที่เก็บรวบรวมจะถูกนำไปใช้เพื่อ:\n\n'
                                    '- ให้บริการที่ดีที่สุด เช่น การจัดส่ง การติดต่อกลับ หรือการสนับสนุนด้านบริการลูกค้า\n'
                                    '- วิเคราะห์เพื่อพัฒนาปรับปรุงผลิตภัณฑ์และบริการ\n'
                                    '- ส่งข้อมูลข่าวสาร โปรโมชั่น และข้อเสนอพิเศษ (หากท่านยินยอม)\n'
                                    '- ปฏิบัติตามข้อกำหนดทางกฎหมายและกฎระเบียบ\n\n'
                                    '3. การเปิดเผยข้อมูลส่วนบุคคล\n'
                                    'เราจะไม่เปิดเผยข้อมูลส่วนบุคคลของท่านแก่บุคคลที่สาม ยกเว้นในกรณีดังต่อไปนี้:\n\n'
                                    '- เมื่อได้รับการอนุญาตจากท่านอย่างชัดเจน\n'
                                    '- เมื่อมีความจำเป็นทางกฎหมาย หรือคำสั่งศาล\n'
                                    '- เมื่อมีการให้บริการร่วมกับพันธมิตรที่มีการรักษาความปลอดภัยและข้อบังคับที่เหมาะสม\n\n'
                                    '4. การรักษาความปลอดภัยของข้อมูล\n'
                                    'เรามุ่งมั่นในการป้องกันข้อมูลส่วนบุคคลของท่านจากการเข้าถึง การแก้ไข และการใช้ข้อมูลโดยไม่ได้รับอนุญาต โดยใช้มาตรการรักษาความปลอดภัยที่ทันสมัย รวมถึงการเข้ารหัสข้อมูลและการจัดการสิทธิ์การเข้าถึง\n\n'
                                    '5. สิทธิของผู้ใช้งาน\n'
                                    'ท่านมีสิทธิ์ในการ:\n\n'
                                    '- ขอเข้าถึงและตรวจสอบข้อมูลส่วนบุคคลของท่าน\n'
                                    '- ขอแก้ไขหรือเปลี่ยนแปลงข้อมูลส่วนบุคคล\n'
                                    '- ขอให้ลบหรือระงับการใช้ข้อมูลส่วนบุคคล\n'
                                    '- เพิกถอนความยินยอมในการใช้ข้อมูลส่วนบุคคลในอนาคต\n\n'
                                    '6. การเปลี่ยนแปลงนโยบาย\n'
                                    'เราขอสงวนสิทธิ์ในการปรับปรุงหรือแก้ไขข้อตกลงและเงื่อนไขในการเก็บข้อมูลส่วนบุคคลนี้ โดยจะแจ้งให้ทราบถึงการเปลี่ยนแปลงผ่านทางเว็บไซต์หรือช่องทางที่เหมาะสม\n',
                                    softWrap: true,
                                  ),
                                )),
                                actions: [
                                  TextButton(
                                    child: Text('Accept'),
                                    onPressed: () {
                                      setState(() {
                                        isAccept = true;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Close'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text(
                          'Consent and Conditions',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
                              builder: (context) => LoginScreen()));
                    },
                    child: const Text(
                      "Did you have an Account? Login now",
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
