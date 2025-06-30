import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:project/Adminpage/profileforadmin.dart';
import 'package:project/screen/myip.dart';

class UserReport extends StatefulWidget {
  final String email;
  const UserReport({required this.email, super.key});

  @override
  State<UserReport> createState() => _UserReportState();
}

class _UserReportState extends State<UserReport> {
  List<dynamic> reports = [];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      String url = '${MyIp().domain}:3000/getreportsuser';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
        });
      } else {
        print('Failed to load reports');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      String url = '${MyIp().domain}:3000/deletereportuser';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Report deleted successfully');
        fetchReports();
      } else {
        Fluttertoast.showToast(msg: 'Failed to delete report');
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
          'User Reports',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      body: reports.isEmpty
          ? const Center(child: Text('No reports found'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[300],
                        backgroundImage: report['profile_image'] != null
                            ? NetworkImage(
                                '${MyIp().domain}:3000/editimageprofile/${report['profile_image']}')
                            : null,
                        child: report['profile_image'] == null
                            ? Text(
                                report['email'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(report['username'] ?? 'Unknown User'),
                      subtitle: Text('Report message: ${report['messages']}'),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Delete"),
                                content: Text(
                                    "Are you sure you want to delete this report?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Cancel deletion
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Confirm deletion
                                      deleteReport(
                                          report['reportu_id'].toString());
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      "Yes",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profileforadmin(
                              email: report['email'],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
