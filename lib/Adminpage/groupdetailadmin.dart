import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/Adminpage/profileforadmin.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;

class Groupdetailadmin extends StatefulWidget {
  final String groupName;
  final String emailOwner;
  final String typeGroup;
  final String groupCode;
  final String? emailCurrent;
  final String nameplace;
  final List<String> imagePath;
  final String latitude;
  final String longitude;
  final String groupstatus;
  final String statusMessage;

  const Groupdetailadmin({
    super.key,
    required this.groupName,
    required this.emailOwner,
    required this.typeGroup,
    required this.groupCode,
    required this.emailCurrent,
    required this.nameplace,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.groupstatus,
    required this.statusMessage,
  });

  @override
  State<Groupdetailadmin> createState() => _GroupdetailadminState();
}

class _GroupdetailadminState extends State<Groupdetailadmin> {
  final TextEditingController commentController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> participants = [];
  Map<String, dynamic>? owner;

  @override
  void initState() {
    super.initState();
    fetchComments();
    viewParticipants();
    viewOwner();
  }

  Color statusColor(String statusMessage) {
    if (statusMessage == 'กิจกรรมสิ้นสุด') {
      return Colors.red;
    } else if (statusMessage == 'กิจกรรมยกเลิก') {
      return Colors.grey;
    } else if (statusMessage == 'กิจกรรมกำลังดำเนินการ') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Future<void> viewParticipants() async {
    try {
      var response = await http.get(
        Uri.parse(
            '${MyIp().domain}:3000/getmembergroup?group_code=${widget.groupCode}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          participants = List<Map<String, dynamic>>.from(data['participants']);
        });
      } else {
        throw Exception(
            'Failed to load participants. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: '$e');
    }
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

  Future<void> submitComment() async {
    if (commentController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please a text.");
      return;
    }
    try {
      String url = '${MyIp().domain}:3000/addcomment';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_code': widget.groupCode,
          'email': widget.emailCurrent,
          'comment_text': commentController.text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (res.statusCode == 200) {
        commentController.clear();
        Fluttertoast.showToast(msg: "Successfully submitted comment.");
        fetchComments();
      } else {
        throw Exception('Failed to submit comment');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Failed to submit comment.");
    }
  }

  Future<void> fetchComments() async {
    var response = await http.get(
      Uri.parse(
          '${MyIp().domain}:3000/getcomment?group_code=${widget.groupCode}'),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      setState(() {
        comments = List<Map<String, dynamic>>.from(data['comments']);
      });
    } else {
      Fluttertoast.showToast(msg: "Failed to load comment.");
    }
  }

  Future<void> deleteComment(int comment_id) async {
    try {
      String url = '${MyIp().domain}:3000/deletecomment';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment_id': comment_id}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        fetchComments();
      } else {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  Future<void> confirmdeletecomment(int comment_id) async {
    bool? confirmdelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure to delete comment?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmdelete == true) {
      await deleteComment(comment_id);
    }
  }

  Future<void> viewOwner() async {
    try {
      var response = await http.get(
        Uri.parse(
            '${MyIp().domain}:3000/getgroupowner?group_code=${widget.groupCode}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          owner = data['owner'];
        });
      } else {
        throw Exception(
            'Failed to load owner. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: '$e');
    }
  }

  Future<void> deleteGroup(BuildContext context) async {
    try {
      String url = '${MyIp().domain}:3000/deletegroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'group_code': widget.groupCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
      } else {
        throw Exception('Failed to delete group');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        actions: <Widget>[
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
                    title: Text('Are you sure to delete Group?'),
                    actions: [
                      TextButton(
                        child: Text('Cancle'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Delete'),
                        onPressed: () {
                          deleteGroup(context);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Owner',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.pink),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pinkAccent,
                backgroundImage: owner != null &&
                        owner?['profile_image'] != null
                    ? NetworkImage(
                        '${MyIp().domain}:3000/editimageprofile/${owner!['profile_image']}')
                    : null,
                child: owner != null && owner?['profile_image'] == null
                    ? Text(
                        owner!['username'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(
                '${owner != null ? owner!['username'] : ''}',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profileforadmin(
                      email: owner?['email'],
                    ),
                  ),
                );
              },
              trailing: Text(
                owner?['join_status'] == '1' ? 'มา' : 'ไม่มา',
                style: TextStyle(
                  color:
                      owner?['join_status'] == '1' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Members',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.pink),
              ),
            ),
            ...participants.map((participant) {
              if (participant['email_member'] ==
                  participants[0]['email_owner']) {
                return SizedBox.shrink();
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple[300],
                  backgroundImage: participant['profile_image'] != null
                      ? NetworkImage(
                          '${MyIp().domain}:3000/editimageprofile/${participant['profile_image']}')
                      : null,
                  child: participant['profile_image'] == null
                      ? Text(
                          participant['email_member'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(
                  participant['username'],
                  style: TextStyle(color: Colors.purple[400]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profileforadmin(
                        email: participant['email_member'],
                      ),
                    ),
                  );
                },
                trailing: Text(
                  participant['join_status'] == '1' ? 'มา' : 'ไม่มา',
                  style: TextStyle(
                    color: participant['join_status'] == '1'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: widget.imagePath.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      '${MyIp().domain}:3000/postgroup/${widget.imagePath[index]}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: Center(child: Text('Failed to load image')),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.statusMessage,
              style: TextStyle(
                  color: statusColor(widget.statusMessage),
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.groupName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Owner :${owner?['username'] ?? ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            InkWell(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place, color: Colors.pink),
                  Text(
                    widget.nameplace,
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Add a comment',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: Colors.pink),
                        onPressed: submitComment,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 300,
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Card(
                          elevation: 2.0,
                          margin: EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 4.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 10.0),
                              leading: CircleAvatar(
                                radius: 14.0,
                                backgroundColor: Colors.pinkAccent,
                                backgroundImage: comment != null &&
                                        comment['profile_image'] != null
                                    ? NetworkImage(
                                        '${MyIp().domain}:3000/editimageprofile/${comment['profile_image']}')
                                    : null,
                                child: comment != null &&
                                        comment['profile_image'] == null
                                    ? Text(
                                        comment['username'] != null
                                            ? comment['username'][0]
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.0),
                                      )
                                    : null,
                              ),
                              title: Text(
                                comment != null && comment['username'] != null
                                    ? comment['username']
                                    : 'Unknown User',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment != null &&
                                            comment['comment_text'] != null
                                        ? comment['comment_text']
                                        : 'No comment text',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    comment != null &&
                                            comment['timestamp'] != null
                                        ? timeAgo(DateTime.parse(
                                            comment['timestamp']))
                                        : '',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        size: 18.0, color: Colors.red),
                                    onPressed: () {
                                      if (comment != null) {
                                        confirmdeletecomment(
                                            comment['comment_id']);
                                      }
                                    },
                                  ),
                                ],
                              )),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                  color: Colors.white,
                  iconSize: 36.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
