import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/screen/myip.dart';

class Viewyourgroup extends StatefulWidget {
  final String email;

  const Viewyourgroup({
    super.key,
    required this.email,
  });

  @override
  State<Viewyourgroup> createState() => _ViewyourgroupState();
}

class _ViewyourgroupState extends State<Viewyourgroup> {
  List<Map<String, dynamic>> userGroups = [];
  Future<void> viewData() async {
    try {
      String url = '${MyIp().domain}:3000/viewjoingroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          userGroups = List<Map<String, dynamic>>.from(data['userGroups']);
        });
        print(data);
      } else if (res.statusCode == 404) {
        setState(() {
          userGroups = [];
        });
      } else {
        throw Exception('Failed to load group data: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    viewData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Group"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => (BottomNavigationPage())));
          },
        ),
      ),
      body: ListView.builder(
        itemCount: userGroups.length,
        itemBuilder: (context, index) {
          final allgroupsData = userGroups[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(allgroupsData['group_name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Owner: ${allgroupsData['email_owner']}'),
                  Text('Type: ${allgroupsData['type_group']}'),
                ],
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => (BottomNavigationPage())));
              },
            ),
          );
        },
      ),
    );
  }
}
