import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/pages/groupdetail.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/profileother.dart';
import 'package:project/pages/user.dart';
import 'dart:convert';

import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notifications_Page extends StatefulWidget {
  State<Notifications_Page> createState() => _Notifications_PageState();
  final String? emailCurrent;
  Notifications_Page({required this.emailCurrent});
}

class _Notifications_PageState extends State<Notifications_Page> {
  List<Map<String, dynamic>> notifications = [];
  int notificationCount = 0;

  Future<void> getNotifications() async {
    try {
      var response = await http.get(
        Uri.parse(
          '${MyIp().domain}:3000/getnotifications?email=${widget.emailCurrent}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data');
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(data['notifications']);
          notificationCount = notifications.length;
        });
        print('Notifications: $notifications');
      } else {
        print('Failed to load notifications');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteNotification(int id, String type) async {
    try {
      String url = '${MyIp().domain}:3000/deletenotifications';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'type': type}),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          notifications.removeWhere((notification) =>
              notification['type'] == type && notification['noti_id'] == id ||
              notification['notif_id'] == id ||
              notification['notig_id'] == id);
          notificationCount = notifications.length;
        });
      } else {
        print(
            'Failed to delete notification. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getNotifications();
    checkTimeoutStatus();
    getUserStatus();
  }

  String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} วินาทีที่แล้ว';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${difference.inDays} วันที่แล้ว';
    }
  }

  bool EventEndStatus(String eventDate, String eventTime, String groupStatus) {
    DateFormat dateFormat = DateFormat('d/M/yyyy h:mm a');
    DateTime now = DateTime.now();
    DateTime eventDateTime = dateFormat.parse('$eventDate $eventTime');

    // หาก groupStatus เป็น '1' (กิจกรรมสิ้นสุด) หรือ '2' (กิจกรรมยกเลิก) ให้คืนค่าจริง
    if (groupStatus == '1' || groupStatus == '2') {
      return true;
    }
    return now.isAfter(eventDateTime);
  }

  String getEventStatusMessage(
      String eventDate, String eventTime, String groupStatus) {
    bool isEventEnded = EventEndStatus(eventDate, eventTime, groupStatus);

    if (groupStatus == '1') {
      return 'กิจกรรมสิ้นสุด';
    } else if (groupStatus == '2') {
      return 'กิจกรรมยกเลิก'; // เพิ่มเงื่อนไขสำหรับกิจกรรมยกเลิก
    } else if (isEventEnded) {
      return 'กิจกรรมกำลังดำเนินการ';
    } else {
      return 'กิจกรรมยังไม่เริ่ม';
    }
  }

  Widget EventStatus(String eventDate, String eventTime, String groupStatus) {
    String statusMessage =
        getEventStatusMessage(eventDate, eventTime, groupStatus);
    Color statusColor;

    // ตรวจสอบสถานะและตั้งค่าสีที่เหมาะสม
    if (statusMessage == 'กิจกรรมสิ้นสุด') {
      statusColor = Colors.red;
    } else if (statusMessage == 'กิจกรรมกำลังดำเนินการ') {
      statusColor = Colors.orange;
    } else if (statusMessage == 'กิจกรรมยกเลิก') {
      statusColor = Colors.grey; // คุณสามารถปรับสีที่นี่ได้ตามต้องการ
    } else {
      statusColor = Colors.green; // กิจกรรมยังไม่เริ่ม
    }

    return Text(
      statusMessage,
      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> getUserStatus() async {
    if (widget.emailCurrent == null) {
      print('Email is null, cannot check user status');
      return;
    }

    String url = '${MyIp().domain}:3000/checkbanstatus';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.emailCurrent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User status: ${data['status']}');

        if (data['status'] == '0') {
          showBanDialog();
        } else {
          print('User is not banned. Status: ${data['status']}');
        }
      } else {
        print('Error retrieving user status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while calling API: $e');
    }
  }

  void showBanDialog() {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Account Banned'),
            content: Text('Your account has been banned. Please log out.'),
            actions: <Widget>[
              TextButton(
                child: Text('Logout'),
                onPressed: () async {
                  await User.setsignin(false);
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  await preferences.remove('email');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
            ],
          );
        },
      );
    } else {
      print('Context is invalid, cannot show dialog');
    }
  }

  Future<void> checkTimeoutStatus() async {
    if (widget.emailCurrent == null) {
      print('Email is null, cannot check timeout status');
      return;
    }

    String url = '${MyIp().domain}:3000/checktimeout';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.emailCurrent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data');

        DateTime? timeoutUntil;
        if (data['timeoutUntil'] != null) {
          timeoutUntil = DateTime.parse(data['timeoutUntil']);
        }

        if (timeoutUntil != null && DateTime.now().isBefore(timeoutUntil)) {
          showTimeoutDialog();
        }
      } else {
        print('Error retrieving timeout status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while calling API: $e');
    }
  }

  void showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Timeout'),
          content: Text('Your account has been  timed out'),
          actions: <Widget>[
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                await User.setsignin(false);
                SharedPreferences preferences =
                    await SharedPreferences.getInstance();
                await preferences.remove('email');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notificationlist = notifications[index];
                final message = notificationlist['message'] ?? 'No message';
                final createAt = notificationlist['created_at'];
                final timeString =
                    createAt != null ? timeAgo(DateTime.parse(createAt)) : '';
                final notificationType = notificationlist['type'] ?? 'group';
                List<String> imagePath =
                    List<String>.from(notificationlist['image_path'] ?? []);

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink,
                      backgroundImage: notificationType == 'groupend' &&
                              notificationlist['image_path'] != null &&
                              notificationlist['image_path'] is List &&
                              notificationlist['image_path'].isNotEmpty
                          ? NetworkImage(
                              '${MyIp().domain}:3000/postgroup/${notificationlist['image_path'][0]}')
                          : (notificationlist['profile_image'] != null &&
                                  notificationlist['profile_image'].isNotEmpty
                              ? NetworkImage(
                                  '${MyIp().domain}:3000/editimageprofile/${notificationlist['profile_image']}')
                              : null),
                      child: notificationType != 'groupend' &&
                              (notificationlist['profile_image'] == null ||
                                  notificationlist['profile_image'].isEmpty)
                          ? Text(
                              notificationlist['user_email'][0].toUpperCase(),
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            )
                          : null,
                    ),
                    title: Text(
                      message,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      timeString,
                      style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    contentPadding: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: Colors.white,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (notificationType == 'group') {
                          deleteNotification(
                              notificationlist['noti_id'], 'group');
                        } else if (notificationType == 'friend') {
                          deleteNotification(
                              notificationlist['notif_id'], 'friend');
                        } else if (notificationType == 'groupend') {
                          deleteNotification(
                              notificationlist['notig_id'], 'groupend');
                        }
                        getNotifications();
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      String statusMessage = '';

                      if (notificationType == 'group' ||
                          notificationType == 'groupend') {
                        statusMessage = getEventStatusMessage(
                          notificationlist['date'],
                          notificationlist['time'],
                          notificationlist['group_status'],
                        );
                      }

                      if (notificationType == 'group') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailPage(
                              groupName: notificationlist['group_name'],
                              emailOwner: notificationlist['email_owner'],
                              typeGroup: notificationlist['type_group'],
                              groupCode: notificationlist['group_code'],
                              emailCurrent: widget.emailCurrent,
                              nameplace: notificationlist['placename'],
                              imagePath: imagePath,
                              latitude: notificationlist['latitude'],
                              longitude: notificationlist['longitude'],
                              groupstatus: notificationlist['group_status'],
                              statusMessage: statusMessage,
                              groupId: notificationlist['id_group'].toString(),
                              date: notificationlist['date'],
                              time: notificationlist['time'],
                            ),
                          ),
                        );
                      } else if (notificationType == 'friend') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profileother(
                              email: notificationlist['user_email'],
                              emailCurrent: widget.emailCurrent,
                            ),
                          ),
                        );
                      } else if (notificationType == 'groupend') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailPage(
                              groupName: notificationlist['group_name'],
                              emailOwner: notificationlist['email_owner'],
                              typeGroup: notificationlist['type_group'],
                              groupCode: notificationlist['group_code'],
                              emailCurrent: widget.emailCurrent,
                              nameplace: notificationlist['placename'],
                              imagePath: imagePath,
                              latitude: notificationlist['latitude'],
                              longitude: notificationlist['longitude'],
                              groupstatus: notificationlist['group_status'],
                              statusMessage: statusMessage,
                              groupId: notificationlist['id_group'].toString(),
                              date: notificationlist['date'],
                              time: notificationlist['time'],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
    );
  }
}
