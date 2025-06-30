import 'package:flutter/material.dart';
import 'package:project/pages/home_pages.dart';
import 'package:project/pages/messages_page.dart';
import 'package:project/pages/profile_page.dart';
import 'package:project/pages/settings_page.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key});
  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  int myCurrentIndex = 0;

  List pages = const [
    HomePage(),
    ProfilePage(),
    MessagePage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 20),
            )
          ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
                currentIndex: myCurrentIndex,
                backgroundColor: Colors.white,
                selectedItemColor: const Color.fromARGB(255, 237, 19, 95),
                unselectedItemColor: Colors.black,
                selectedFontSize: 12,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                onTap: (index) {
                  setState(() {
                    myCurrentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_outlined), label: 'Profile'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.message_outlined), label: 'Message'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ]),
          ),
        ),
        body: pages[myCurrentIndex]);
  }
}
