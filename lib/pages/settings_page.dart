import 'package:flutter/material.dart';
import 'package:project/pages/editpassword.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/resetpass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // ignore: prefer_typing_uninitialized_variables
  var finalEmail;
  Future<void> getShared() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      finalEmail = sharedPreferences.getString('email');
      print("SharedPreferences Email: $finalEmail");
    });
  }

  Future<void> getData() async {
    await getShared();
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> logout() async {
    await User.setsignin(false);
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.remove('email');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 16.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Editpassword(
                            email: finalEmail,
                          )),
                );
              },
              child: const Text(
                "Reset Password",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const Divider(
            color: Colors.black,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 16.0),
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'Rules',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                      content: const Text(
                          '1. ประเภทกิจกรรมที่สร้างควรจะอยู่ในประเภทที่เหมาะสม.\n'
                          '2. การกดเข้าร่วมกิจกรรมควรพิจารณาให้ดีก่อน.\n'
                          '3. เมื่อเข้าร่วมกิจกรรมแล้วท่านต้องอยู่ภายในรัศมี 500 เมตรจากหมุดท่านถึงจะ Checkin ได้ \n'
                          '4. โดยมีระยะเวลเช็คอินได้ 1 ชั่วโมงนับตั้งแต่กิจกรรมเริ่ม\n'
                          '5. หากท่าน checkin ตามกำหนดเวลาได้ ท่านจะได้รับเพิ่ม 1 เครดิต\n'
                          '6. หากท่าน checkin ไม่ทันตามกำหนดเวลา ท่านจะโดนหัก 1 เตรดิต\n'
                          '7. หากท่านลบกลุ่มก่อนที่จะถึงเวลากิจกรรมท่านจะถูกลบเครดิต 2 เครดิค\n'
                          '8. หากท่านยกเลิกกิจกรรมท่านจะถูกหักเครดิต 1 เครดิต'
                          '9. หากท่านเครดิตเหลือ 0 ท่านจะถูกดำเนินการแบนโดยอัตโนมัติ \n'
                          '10. หากท่านพบกิจกรรมที่ไม่เหมาะสมกรุณารีพอร์ทมายังแอดมิน\n'
                          '11. กรุณาใช้ถ้อยคำที่เหมาะสมและไม่หยาบคาย'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Close',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text(
                "Rule",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const Divider(
            color: Colors.black,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 16.0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Resetpass(
                            email: finalEmail,
                          )),
                );
              },
              child: const Text(
                "Forgot Password",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const Divider(
            color: Colors.black,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await logout();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "LOGOUT",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
