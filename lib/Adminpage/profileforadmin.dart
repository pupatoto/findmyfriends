import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project/Adminpage/groupdetailadmin.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Profileforadmin extends StatefulWidget {
  final String email;
  const Profileforadmin({
    super.key,
    required this.email,
  });

  @override
  State<Profileforadmin> createState() => _ProfileforadminState();
}

class _ProfileforadminState extends State<Profileforadmin> {
  var username;
  var userid;
  var profileImage;
  var birthdate;
  String? age;
  var gender;
  var credit;
  var status;

  @override
  void initState() {
    super.initState();
    viewData();
  }

  Future<void> viewData() async {
    try {
      String url = '${MyIp().domain}:3000/currentuser';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        setState(() {
          username = data['user']['username'];
          userid = data['user']['user_id'];
          profileImage = data['user']['profile_image'];
          birthdate = data['user']['birth_date'];
          age = data['user']['age'];
          gender = data['user']['gender'];
          credit = data['user']['credits'];
          status = data['user']['status'];
        });
        print(data);
        print(widget.email);
      } else {
        print('Failed to load data');
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
        await viewData();
      } else {
        Fluttertoast.showToast(msg: 'Failed to time out user');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            if (status != '0')
              TextButton(
                child: Text(
                  "BAN",
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await banUser(userid.toString());
                  await viewData();
                  setState(() {});
                },
              ),
            if (status != '1')
              TextButton(
                child: Text(
                  "UNBAN",
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await unbanUser(userid.toString());
                  await viewData();
                  setState(() {});
                },
              ),
            IconButton(
              icon: Icon(Icons.lock_clock_outlined,
                  size: 18.0, color: Colors.grey),
              onPressed: () async {
                int? selectedDuration;
                String selectedUnit = 'minutes'; // หน่วยเวลาเริ่มต้น

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
                                decoration: InputDecoration(hintText: "Enter"),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  selectedDuration = int.tryParse(value);
                                },
                              ),
                              DropdownButton<String>(
                                value: selectedUnit,
                                items: [
                                  DropdownMenuItem(
                                      value: 'minutes', child: Text('Minutes')),
                                  DropdownMenuItem(
                                      value: 'hours', child: Text('Hours')),
                                  DropdownMenuItem(
                                      value: 'days', child: Text('Days')),
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
                                          selectedDuration! * 60;
                                      break;
                                    case 'hours':
                                      durationInSeconds =
                                          selectedDuration! * 3600;
                                      break;
                                    case 'days':
                                      durationInSeconds =
                                          selectedDuration! * 86400;
                                      break;
                                  }
                                }
                                Navigator.pop(context, durationInSeconds);
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
                  await timeOutUser(userid.toString(), duration);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
            ),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.pinkAccent,
                  backgroundImage: profileImage != null
                      ? NetworkImage(
                          '${MyIp().domain}:3000/editimageprofile/$profileImage')
                      : null,
                  child: profileImage == null
                      ? Text(
                          widget.email != null
                              ? widget.email[0].toUpperCase()
                              : 'N/A',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                "ID: ${userid ?? 'No userid found'}",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            Center(
              child: Text(
                "${username ?? 'No username found'}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            Center(
              child: Text(
                "Age: ${age ?? 'No age found'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            Center(
              child: Text(
                "Gender: ${gender ?? 'No gender found'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            Center(
              child: Text(
                "Credit: ${credit ?? 'No credit found'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(height: 10),
            TabBar(
              indicatorColor: Colors.pink,
              labelColor: Colors.pink,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3.0,
              tabs: [
                Tab(text: "Post"),
                Tab(text: "Participate"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  UserGroupsView(
                    email: widget.email,
                  ),
                  ParticipateView(
                    email: widget.email,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserGroupsView extends StatefulWidget {
  final String? email;
  final String? emailCurrent;

  UserGroupsView({Key? key, this.email, this.emailCurrent}) : super(key: key);

  @override
  UserGroupsViewState createState() => UserGroupsViewState();
}

class UserGroupsViewState extends State<UserGroupsView> {
  List<Map<String, dynamic>> group = [];
  Map<String, bool> groupJoinStatus = {};
  Map<String, bool> groupLikeStatus = {};

  @override
  void initState() {
    super.initState();
    viewPostGroup();
  }

  Future<void> toggleGroupStatus(
    String groupName,
    String emailOwner,
    String groupType,
    String groupCode,
  ) async {
    if (widget.emailCurrent == null) {
      Fluttertoast.showToast(msg: 'No email found in SharedPreferences');
      return;
    }
    try {
      String url = '${MyIp().domain}:3000/joingroup';
      String action =
          groupJoinStatus[groupCode] == true ? 'leavegroup' : 'joingroup';

      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_member': widget.emailCurrent,
          'group_name': groupName,
          'type_group': groupType,
          'group_code': groupCode,
          'email': emailOwner,
          'action': action,
        }),
      );
      var data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          bool currentStatus = groupJoinStatus[groupCode] ?? false;
          groupJoinStatus[groupCode] = !currentStatus;
        });

        if (groupJoinStatus[groupCode] == true) {
          Fluttertoast.showToast(msg: 'Successfully joined the group');
        } else {
          Fluttertoast.showToast(msg: 'Successfully left the group');
        }
        await saveGroupJoinStatus(groupCode, groupJoinStatus[groupCode]!);
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'An error occurred');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> toggleLikeStatus(String groupCode) async {
    if (widget.emailCurrent == null) {
      Fluttertoast.showToast(msg: 'No email found in SharedPreferences');
      return;
    }
    try {
      String url = '${MyIp().domain}:3000/likegroup';
      String action =
          groupLikeStatus[groupCode] == true ? 'unlikegroup' : 'likegroup';

      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_like': widget.emailCurrent,
          'group_code': groupCode,
          'action': action,
        }),
      );

      var data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          bool currentLikeStatus = groupLikeStatus[groupCode] ?? false;
          groupLikeStatus[groupCode] = !currentLikeStatus;
        });

        if (groupLikeStatus[groupCode] == true) {
          Fluttertoast.showToast(msg: 'Successfully liked the group');
        } else {
          Fluttertoast.showToast(msg: 'Successfully unliked the group');
        }

        await saveGroupLikeStatus(groupCode, groupLikeStatus[groupCode]!);
      } else {
        Fluttertoast.showToast(msg: 'Failed to toggle like status');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> viewPostGroup() async {
    try {
      String url = '${MyIp().domain}:3000/viewyourpostgroup';
      var res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          group = List<Map<String, dynamic>>.from(data['userGroups']);
        });
        await loadGroupJoinStatus();
        await loadGroupLikeStatus();
      } else if (res.statusCode == 404) {
        setState(() {
          group = [];
        });
      } else {
        throw Exception('Failed to load group data: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  bool EventEndStatus(String eventDate, String eventTime, String groupStatus) {
    DateFormat dateFormat = DateFormat('d/M/yyyy h:mm a');
    DateTime now = DateTime.now();
    DateTime eventDateTime = dateFormat.parse('$eventDate $eventTime');
    if (groupStatus == '1') {
      return true;
    }
    return now.isAfter(eventDateTime);
  }

  Widget EventStatus(String eventDate, String eventTime, String groupStatus) {
    bool isEventEnded = EventEndStatus(eventDate, eventTime, groupStatus);

    String statusMessage;
    Color statusColor;

    if (groupStatus == '1') {
      statusMessage = 'กิจกรรมสิ้นสุด';
      statusColor = Colors.red;
    } else if (isEventEnded) {
      statusMessage = 'กิจกรรมกำลังดำเนินการ';
      statusColor = Colors.orange;
    } else {
      statusMessage = 'กิจกรรมยังไม่เริ่ม';
      statusColor = Colors.green;
    }

    return Text(
      statusMessage,
      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> saveGroupJoinStatus(String groupCode, bool isJoined) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('join_$groupCode', isJoined);
  }

  Future<void> loadGroupJoinStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      group.forEach((group) {
        String code = group['group_code'];
        groupJoinStatus[code] = prefs.getBool('join_$code') ?? false;
      });
    });
  }

  Future<void> saveGroupLikeStatus(String groupCode, bool isLiked) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('like_$groupCode', isLiked);
  }

  Future<void> loadGroupLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      group.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] = prefs.getBool('like_$code') ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: group.isEmpty
          ? Center(
              child: Text(
                "No groups found for ${widget.email ?? 'No email'}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: group.length,
              itemBuilder: (context, index) {
                final groupPost = group[index];
                List<String> imagePath =
                    List<String>.from(groupPost['image_path'] ?? []);
                final participantCount = groupPost['participant_count'] ?? 0;
                final maxParticipants = groupPost['max_participants'] ?? 0;
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePath != null && imagePath.isNotEmpty)
                            SizedBox(
                              height: 150,
                              child: PageView.builder(
                                itemCount: imagePath.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: Image.network(
                                      '${MyIp().domain}:3000/postgroup/${imagePath[index]}',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Image loading error: $error');
                                        return Container(
                                          color: Colors.grey,
                                          child: Center(
                                            child: Text('Failed to load image'),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              height: 150,
                              color: Colors.grey,
                              child: Center(
                                child: Text('No Image'),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ListTile(
                              title: Text(
                                groupPost['group_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type : ${groupPost['type_group']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Location : ${groupPost['placename']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Date : ${groupPost['date']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Time : ${groupPost['time']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Age : ${groupPost['age']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Gender : ${groupPost['gender']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Participants: $participantCount/$maxParticipants',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                String statusMessage;
                                String groupStatus = groupPost['group_status'];
                                if (groupStatus == '1') {
                                  statusMessage = 'กิจกรรมสิ้นสุด';
                                } else if (EventEndStatus(groupPost['date'],
                                    groupPost['time'], groupStatus)) {
                                  statusMessage = 'กิจกรรมกำลังดำเนินการ';
                                } else {
                                  statusMessage = 'กิจกรรมยังไม่เริ่ม';
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Groupdetailadmin(
                                      groupName: groupPost['group_name'],
                                      emailOwner: groupPost['email_owner'],
                                      typeGroup: groupPost['type_group'],
                                      groupCode: groupPost['group_code'],
                                      emailCurrent: widget.email,
                                      nameplace: groupPost['placename'],
                                      imagePath: imagePath,
                                      latitude: groupPost['latitude'],
                                      longitude: groupPost['longitude'],
                                      groupstatus: groupPost['group_status'],
                                      statusMessage: statusMessage,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: EventStatus(groupPost['date'],
                              groupPost['time'], groupPost['group_status']),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ParticipateView extends StatefulWidget {
  final String? email;
  final String? emailCurrent;
  ParticipateView({Key? key, this.email, this.emailCurrent});
  @override
  State<ParticipateView> createState() => ParticipateViewState();
}

class ParticipateViewState extends State<ParticipateView> {
  List<Map<String, dynamic>> group = [];
  Map<String, bool> groupJoinStatus = {};
  Map<String, bool> groupLikeStatus = {};

  @override
  void initState() {
    super.initState();
    viewJoinGroup();
  }

  Future<void> viewJoinGroup() async {
    try {
      String url = '${MyIp().domain}:3000/viewjoingroup';
      var res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          group = List<Map<String, dynamic>>.from(data['userGroups']);
        });
        await loadGroupJoinStatus();
        await loadGroupLikeStatus();
      } else if (res.statusCode == 404) {
        setState(() {
          group = [];
        });
      } else {
        throw Exception('Failed to load group data: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> toggleGroupStatus(
    String groupName,
    String emailOwner,
    String groupType,
    String groupCode,
  ) async {
    if (widget.email == null) {
      Fluttertoast.showToast(msg: 'No email found in SharedPreferences');
      return;
    }
    try {
      String url = '${MyIp().domain}:3000/joingroup';
      String action =
          groupJoinStatus[groupCode] == true ? 'leavegroup' : 'joingroup';

      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_member': widget.email,
          'group_name': groupName,
          'type_group': groupType,
          'group_code': groupCode,
          'email': emailOwner,
          'action': action,
        }),
      );
      var data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          bool currentStatus = groupJoinStatus[groupCode] ?? false;
          groupJoinStatus[groupCode] = !currentStatus;
        });

        if (groupJoinStatus[groupCode] == true) {
          Fluttertoast.showToast(msg: 'Successfully joined the group');
        } else {
          Fluttertoast.showToast(msg: 'Successfully left the group');
        }
        await saveGroupJoinStatus(groupName, groupJoinStatus[groupCode]!);
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'An error occurred');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> toggleLikeStatus(String groupCode) async {
    if (widget.email == null) {
      Fluttertoast.showToast(msg: 'No email found in SharedPreferences');
      return;
    }
    try {
      String url = '${MyIp().domain}:3000/likegroup';
      String action =
          groupLikeStatus[groupCode] == true ? 'unlikegroup' : 'likegroup';

      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_like': widget.email,
          'group_code': groupCode,
          'action': action,
        }),
      );

      var data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          bool currentLikeStatus = groupLikeStatus[groupCode] ?? false;
          groupLikeStatus[groupCode] = !currentLikeStatus;
        });

        if (groupLikeStatus[groupCode] == true) {
          Fluttertoast.showToast(msg: 'Successfully liked the group');
        } else {
          Fluttertoast.showToast(msg: 'Successfully unliked the group');
        }

        await saveGroupLikeStatus(groupCode, groupLikeStatus[groupCode]!);
      } else {
        Fluttertoast.showToast(msg: 'Failed to toggle like status');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> saveGroupJoinStatus(String groupCode, bool isJoined) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('join_$groupCode', isJoined);
  }

  Future<void> loadGroupJoinStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      group.forEach((group) {
        String code = group['group_code'];
        groupJoinStatus[code] = prefs.getBool('join_$code') ?? false;
      });
    });
  }

  Future<void> saveGroupLikeStatus(String groupCode, bool isLiked) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('like_$groupCode', isLiked);
  }

  Future<void> loadGroupLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      group.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] =
            prefs.getBool('like_$code') ?? false; // Use 'like_' prefix here
      });
    });
  }

  bool EventEndStatus(String eventDate, String eventTime, String groupStatus) {
    DateFormat dateFormat = DateFormat('d/M/yyyy h:mm a');
    DateTime now = DateTime.now();
    DateTime eventDateTime = dateFormat.parse('$eventDate $eventTime');
    if (groupStatus == '1') {
      return true;
    }
    return now.isAfter(eventDateTime);
  }

  Widget EventStatus(String eventDate, String eventTime, String groupStatus) {
    bool isEventEnded = EventEndStatus(eventDate, eventTime, groupStatus);

    String statusMessage;
    Color statusColor;

    if (groupStatus == '1') {
      statusMessage = 'กิจกรรมสิ้นสุด';
      statusColor = Colors.red;
    } else if (isEventEnded) {
      statusMessage = 'กิจกรรมกำลังดำเนินการ';
      statusColor = Colors.orange;
    } else {
      statusMessage = 'กิจกรรมยังไม่เริ่ม';
      statusColor = Colors.green;
    }

    return Text(
      statusMessage,
      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: group.isEmpty
          ? Center(
              child: Text(
                "No groups found for ${widget.email ?? 'No email'}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: group.length,
              itemBuilder: (context, index) {
                final groupjoin = group[index];
                final isJoined =
                    groupJoinStatus[groupjoin['group_code']] ?? false;
                final isLiked =
                    groupLikeStatus[groupjoin['group_code']] ?? false;
                List<String> imagePath =
                    List<String>.from(groupjoin['image_path'] ?? []);
                final iseventend = EventEndStatus(groupjoin['date'],
                    groupjoin['time'], groupjoin['group_status']);
                final participantCount = groupjoin['participant_count'] ?? 0;
                final maxParticipants = groupjoin['max_participants'] ?? 0;
                return Card(
                  margin: EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePath != null && imagePath.isNotEmpty)
                            SizedBox(
                              height: 150,
                              child: PageView.builder(
                                itemCount: imagePath.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: Image.network(
                                      '${MyIp().domain}:3000/postgroup/${imagePath[index]}',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Image loading error: $error');
                                        return Container(
                                          color: Colors.grey,
                                          child: Center(
                                            child: Text('Failed to load image'),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              height: 150,
                              color: Colors.grey,
                              child: Center(
                                child: Text('No Image'),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ListTile(
                              title: Text(
                                groupjoin['group_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type : ${groupjoin['type_group']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Location : ${groupjoin['placename']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Date : ${groupjoin['date']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Time : ${groupjoin['time']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Age : ${groupjoin['age']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Gender : ${groupjoin['gender']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Participants: $participantCount/$maxParticipants',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                String statusMessage;
                                String groupStatus = groupjoin['group_status'];
                                if (groupStatus == '1') {
                                  statusMessage = 'กิจกรรมสิ้นสุด';
                                } else if (EventEndStatus(groupjoin['date'],
                                    groupjoin['time'], groupStatus)) {
                                  statusMessage = 'กิจกรรมกำลังดำเนินการ';
                                } else {
                                  statusMessage = 'กิจกรรมยังไม่เริ่ม';
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Groupdetailadmin(
                                      groupName: groupjoin['group_name'],
                                      emailOwner: groupjoin['email_owner'],
                                      typeGroup: groupjoin['type_group'],
                                      groupCode: groupjoin['group_code'],
                                      emailCurrent: widget.emailCurrent,
                                      nameplace: groupjoin['placename'],
                                      imagePath: imagePath,
                                      latitude: groupjoin['latitude'],
                                      longitude: groupjoin['longitude'],
                                      groupstatus: groupjoin['group_status'],
                                      statusMessage: statusMessage,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: EventStatus(groupjoin['date'],
                              groupjoin['time'], groupjoin['group_status']),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
