import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project/Adminpage/groupdetailadmin.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;

class GroupReport extends StatefulWidget {
  final String email;
  const GroupReport({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<GroupReport> createState() => _GroupReportState();
}

class _GroupReportState extends State<GroupReport> {
  List<Map<String, dynamic>> groupReport = [];
  String? finalEmail;

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
            groupReport = List<Map<String, dynamic>>.from(data['data']);
          });
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

  Future<void> deleteGroup(String groupCode) async {
    try {
      String url = '${MyIp().domain}:3000/deletegroupfromadmin';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'group_code': groupCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          viewGroupReport();
        });
      } else {
        throw Exception('Failed to delete group');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  Future<void> deleteReport(String groupCode) async {
    try {
      String url = '${MyIp().domain}:3000/deletereport';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'group_code': groupCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          viewGroupReport();
        });
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  @override
  void initState() {
    super.initState();
    viewGroupReport();
  }

  bool EventEndStatus(String eventDate, String eventTime, String groupStatus) {
    DateFormat dateFormat = DateFormat('d/M/yyyy h:mm a');
    DateTime now = DateTime.now();
    DateTime eventDateTime = dateFormat.parse('$eventDate $eventTime');
    if (groupStatus == '1' || groupStatus == '2') {
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
    } else if (groupStatus == '2') {
      statusMessage = 'กิจกรรมยกเลิก';
      statusColor = Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Report',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      body: groupReport.isEmpty
          ? Center(child: Text("No Group Report Found"))
          : ListView.builder(
              itemCount: groupReport.length,
              itemBuilder: (context, index) {
                final group = groupReport[index];
                List<String> imagePath =
                    List<String>.from(group['image_path'] ?? []);
                final participantCount = group['participant_count'] ?? 0;
                final maxParticipants = group['max_participants'] ?? 0;

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
                                group['group_name'] ?? 'Unnamed Group',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type : ${group['type_group'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Location : ${group['placename'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Date : ${group['date'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Time : ${group['time'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Age : ${group['age'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Gender : ${group['gender'] ?? 'Unknown'}',
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
                                  Text(
                                    'Reports: ${group['report_count'] ?? 0} times',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.pink,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Confirm Delete"),
                                            content: Text(
                                                "Are you sure you want to delete this group"),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  deleteGroup(
                                                      group['group_code']);
                                                },
                                                child: Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Confirm Cancel"),
                                            content: Text(
                                                "Are you sure you want to cancel this report?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("No"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  deleteReport(
                                                      group['group_code']);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  "Yes",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                String statusMessage;
                                String groupStatus =
                                    group['group_status'] ?? '';

                                String eventDate = group['date'];
                                String eventTime = group['time'];

                                if (groupStatus == '1') {
                                  statusMessage = 'กิจกรรมสิ้นสุด';
                                } else if (groupStatus == '2') {
                                  statusMessage = 'กิจกรรมยกเลิก';
                                } else if (EventEndStatus(
                                    eventDate, eventTime, groupStatus)) {
                                  statusMessage = 'กิจกรรมกำลังดำเนินการ';
                                } else {
                                  statusMessage = 'กิจกรรมยังไม่เริ่ม';
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Groupdetailadmin(
                                            groupName:
                                                group['group_name'] ?? '',
                                            emailOwner:
                                                group['email_owner'] ?? '',
                                            typeGroup:
                                                group['type_group'] ?? '',
                                            groupCode:
                                                group['group_code'] ?? '',
                                            emailCurrent: finalEmail,
                                            nameplace: group['placename'] ?? '',
                                            imagePath: imagePath,
                                            latitude: group['latitude'] ?? '',
                                            longitude: group['longitude'] ?? '',
                                            groupstatus: groupStatus,
                                            statusMessage: statusMessage,
                                          )),
                                );
                              },
                            ),
                          )
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
                          child: EventStatus(
                              group['date'] ?? 'unknown',
                              group['time'] ?? 'unknown',
                              group['group_status'] ?? '0'),
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
