import 'package:flutter/material.dart';
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/pages/home.dart';

import '../pages/user.dart';

class check_login extends StatefulWidget {
  const check_login({super.key});

  @override
  State<check_login> createState() => _check_loginState();
}

class _check_loginState extends State<check_login> {
  Future checklogin() async {
    bool? signin = await User.getsignin();
    print(signin);
    if (signin == false) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => BottomNavigationPage()));
    }
  }

  void initState() {
    checklogin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
