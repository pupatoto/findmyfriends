import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/Adminpage/groupreport.dart';
import 'package:project/Adminpage/profileforadmin.dart';
import 'package:project/Adminpage/user_report.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/user.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> users = [];
  List<dynamic> filterUsers = [];
  String searchQuery = "";
  var finalEmail;
  int groupReportCount = 0;
  int reportUser = 0;

  Future<void> viewUser() async {
    try {
      String url = '${MyIp().domain}:3000/getallusers';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() {
          users = jsonDecode(res.body);
          filterUsers = users;
        });
      } else if (res.statusCode == 404) {
        print('No users found');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> viewGroupReport() async {
    try {
      String url = '${MyIp().domain}:3000/getgroupreport';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data['success']) {
          setState(() {
            groupReportCount =
                List<Map<String, dynamic>>.from(data['data']).length;
          });
          print(groupReportCount);
        } else {
          print('Error: ${data['message']}');
        }
      } else if (res.statusCode == 404) {
        print('No group report found');
      } else {
        print('Error: ${res.statusCode} ${res.reasonPhrase}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> banUser(String userId) async {
    try {
      String url = '${MyIp().domain}:3000/banuser';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'User banned successfully');
      } else {
        Fluttertoast.showToast(msg: 'User ban failed');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      String url = '${MyIp().domain}:3000/unbanuser';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'User Unbanned successfully');
      } else {
        Fluttertoast.showToast(msg: 'User Unban failed');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> timeOutUser(String userId, int duration) async {
    try {
      String url = '${MyIp().domain}:3000/timeout';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'duration': duration}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'User timed out successfully');
        await viewUser();
      } else {
        Fluttertoast.showToast(msg: 'Failed to time out user');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> fetchReports() async {
    try {
      String url = '${MyIp().domain}:3000/getreportsuser';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          reportUser = List<Map<String, dynamic>>.from(data).length;
          print('reportUser: $reportUser');
        });
      } else {
        print('Failed to load reports');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

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
    viewUser();
    getData();
    viewGroupReport();
    fetchReports();
  }

  Future<void> logout() async {
    await User.setsignin(false);
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.remove('email');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupReport(
                    email: finalEmail,
                  ),
                ),
              ).then((_) {
                viewUser();
                viewGroupReport();
                fetchReports();
              });
            },
            child: Stack(
              children: <Widget>[
                Text(
                  "Group Report",
                  style: TextStyle(color: Colors.red),
                ),
                if (groupReportCount > 0)
                  Positioned(
                    right: 0,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$groupReportCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserReport(
                    email: finalEmail,
                  ),
                ),
              ).then((_) {
                viewUser();
                viewGroupReport();
                fetchReports();
              });
            },
            child: Stack(
              children: <Widget>[
                Text(
                  "User Report",
                  style: TextStyle(color: Colors.green),
                ),
                if (reportUser > 0)
                  Positioned(
                    right: 0,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$reportUser',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.pink,
            ),
            onPressed: () {
              logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterUsers = users.where((user) {
                    return user['username']
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        user['email']
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase());
                  }).toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filterUsers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filterUsers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[300],
                          backgroundImage: filterUsers[index]
                                      ['profile_image'] !=
                                  null
                              ? NetworkImage(
                                  '${MyIp().domain}:3000/editimageprofile/${filterUsers[index]['profile_image']}')
                              : null,
                          child: filterUsers[index]['profile_image'] == null
                              ? Text(
                                  filterUsers[index]['email'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                            filterUsers[index]['username'] ?? 'Unknown User'),
                        subtitle:
                            Text(filterUsers[index]['email'] ?? 'No Email'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Profileforadmin(
                                email: filterUsers[index]['email'],
                              ),
                            ),
                          ).then((_) {
                            viewUser();
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (filterUsers[index]['status'] != '0')
                              TextButton(
                                child: Text(
                                  "BAN",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await banUser(
                                      filterUsers[index]['user_id'].toString());
                                  await viewUser();
                                  setState(() {});
                                },
                              ),
                            if (filterUsers[index]['status'] != '1')
                              TextButton(
                                child: Text(
                                  "UNBAN",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await unbanUser(
                                      filterUsers[index]['user_id'].toString());
                                  await viewUser();
                                  setState(() {});
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.lock_clock_outlined,
                                  size: 18.0, color: Colors.grey),
                              onPressed: () async {
                                int? selectedDuration;
                                String selectedUnit = 'minutes';

                                int? duration = await showDialog<int>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: Text('Set Timeout'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                decoration: InputDecoration(
                                                    hintText: "Enter"),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  selectedDuration =
                                                      int.tryParse(value);
                                                },
                                              ),
                                              DropdownButton<String>(
                                                value: selectedUnit,
                                                items: [
                                                  DropdownMenuItem(
                                                      value: 'minutes',
                                                      child: Text('Minutes')),
                                                  DropdownMenuItem(
                                                      value: 'hours',
                                                      child: Text('Hours')),
                                                  DropdownMenuItem(
                                                      value: 'days',
                                                      child: Text('Days')),
                                                ],
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedUnit = newValue!;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                int? durationInSeconds;
                                                if (selectedDuration != null) {
                                                  switch (selectedUnit) {
                                                    case 'minutes':
                                                      durationInSeconds =
                                                          selectedDuration! *
                                                              60;
                                                      break;
                                                    case 'hours':
                                                      durationInSeconds =
                                                          selectedDuration! *
                                                              3600;
                                                      break;
                                                    case 'days':
                                                      durationInSeconds =
                                                          selectedDuration! *
                                                              86400;
                                                      break;
                                                  }
                                                }
                                                Navigator.pop(
                                                    context, durationInSeconds);
                                              },
                                              child: Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                if (duration != null) {
                                  await timeOutUser(
                                      users[index]['user_id'].toString(),
                                      duration);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
