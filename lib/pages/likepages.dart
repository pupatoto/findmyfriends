import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/pages/groupdetail.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikePage extends StatefulWidget {
  final String finalEmail;

  const LikePage({Key? key, required this.finalEmail}) : super(key: key);

  @override
  _LikePageState createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  List<Map<String, dynamic>> likesData = [];
  Map<String, bool> groupJoinStatus = {};
  Map<String, bool> groupLikeStatus = {};
  @override
  void initState() {
    super.initState();
    viewData();
  }

  Future<void> viewData() async {
    try {
      String url = '${MyIp().domain}:3000/getlikegroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.finalEmail}),
      );

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        setState(() {
          likesData = List<Map<String, dynamic>>.from(data['likedGroups']);
        });
        await loadGroupJoinStatus(widget.finalEmail);
        await loadGroupLikeStatus(widget.finalEmail);
      } else {
        print('Failed to load data: ${res.body}');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> toggleGroupStatus(
    String groupName,
    String emailOwner,
    String groupType,
    String groupCode,
  ) async {
    if (widget.finalEmail == null) {
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
          'email_member': widget.finalEmail,
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
          groupJoinStatus[groupCode] = !groupJoinStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupJoinStatus[groupCode]!
                ? 'Successfully joined the group'
                : 'Successfully left the group');

        await saveGroupJoinStatus(
            groupCode, groupJoinStatus[groupCode]!, widget.finalEmail!);
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'An error occurred');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> toggleLikeStatus(String groupCode) async {
    if (widget.finalEmail == null) {
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
          'email_like': widget.finalEmail,
          'group_code': groupCode,
          'action': action,
        }),
      );

      var data = jsonDecode(res.body);

      if (data['success']) {
        setState(() {
          groupLikeStatus[groupCode] = !groupLikeStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupLikeStatus[groupCode]!
                ? 'Successfully liked the group'
                : 'Successfully unliked the group');

        await saveGroupLikeStatus(
            groupCode, groupLikeStatus[groupCode]!, widget.finalEmail!);
      } else {
        Fluttertoast.showToast(msg: 'Failed to toggle like status');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> saveGroupJoinStatus(
      String groupCode, bool isJoined, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'join_${email}_$groupCode', isJoined); // Use email in the key
  }

  Future<void> loadGroupJoinStatus(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      likesData.forEach((group) {
        String code = group['group_code'];
        groupJoinStatus[code] = prefs.getBool('join_${email}_$code') ?? false;
      });
    });
  }

  Future<void> saveGroupLikeStatus(
      String groupCode, bool isLiked, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'like_${email}_$groupCode', isLiked); // Use email in the key
  }

  Future<void> loadGroupLikeStatus(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      likesData.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] = prefs.getBool('like_${email}_$code') ?? false;
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

  Future<void> reportGroup(String grouCode) async {
    try {
      String url = '${MyIp().domain}:3000/reportgroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupCode': grouCode}),
      );
      var response = jsonDecode(res.body);
      if (res.statusCode == 200) {
        Fluttertoast.showToast(msg: response['message']);
      } else {
        Fluttertoast.showToast(msg: response['message']);
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LIKEPAGE',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      body: likesData.isEmpty
          ? Center(
              child: Text(
                "No groups found for ${widget.finalEmail ?? 'No email'}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: likesData.length,
              itemBuilder: (context, index) {
                final groupjoin = likesData[index];
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
                                    builder: (context) => GroupDetailPage(
                                      groupName: groupjoin['group_name'],
                                      emailOwner: groupjoin['email_owner'],
                                      typeGroup: groupjoin['type_group'],
                                      groupCode: groupjoin['group_code'],
                                      emailCurrent: widget.finalEmail,
                                      nameplace: groupjoin['placename'],
                                      imagePath: imagePath,
                                      latitude: groupjoin['latitude'],
                                      longitude: groupjoin['longitude'],
                                      groupstatus: groupjoin['group_status'],
                                      statusMessage: statusMessage,
                                      groupId: groupjoin['id_group'].toString(),
                                      date: groupjoin['date'],
                                      time: groupjoin['time'],
                                    ),
                                  ),
                                );
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.finalEmail !=
                                      groupjoin['email_owner'])
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        iconSize: 16.0,
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked ? Colors.pink : null,
                                        ),
                                        onPressed: () {
                                          toggleLikeStatus(
                                              groupjoin['group_code']);
                                        },
                                      ),
                                    ),
                                  SizedBox(width: 8.0),
                                  if (!iseventend)
                                    if (widget.finalEmail !=
                                        groupjoin['email_owner'])
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          iconSize: 16.0,
                                          icon: Icon(
                                            isJoined ? Icons.check : Icons.add,
                                            color: isJoined
                                                ? Colors.green
                                                : Colors.pink,
                                          ),
                                          onPressed: () {
                                            toggleGroupStatus(
                                              groupjoin['group_name'],
                                              groupjoin['email_owner'],
                                              groupjoin['type_group'],
                                              groupjoin['group_code'],
                                            );
                                          },
                                        ),
                                      )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: EventStatus(
                                groupjoin['date'],
                                groupjoin['time'],
                                groupjoin['group_status'],
                              ),
                            ),
                            if (widget.finalEmail != groupjoin['email_owner'])
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.black,
                                  size: 20.0,
                                ),
                                onSelected: (String value) {
                                  if (value == 'report') {
                                    print('Report selected');
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<String>(
                                    value: 'report',
                                    child: Text('Report'),
                                  ),
                                ],
                              ),
                          ],
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
