import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/profileother.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFriendScreen extends StatefulWidget {
  final String email;

  const AddFriendScreen({Key? key, required this.email}) : super(key: key);

  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  String errorMessage = '';
  List<dynamic> users = [];
  List<dynamic> filterUsers = [];
  String searchQuery = "";
  List<bool> isFriendAdded = [];
  List<dynamic> friendRequests = [];

  Future<void> viewUser() async {
    try {
      String url = '${MyIp().domain}:3000/getallusersadd?email=${widget.email}';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (res.statusCode == 200) {
        setState(() {
          users = jsonDecode(res.body);
          filterUsers = users;
          if (users.isNotEmpty) {
            isFriendAdded = List<bool>.filled(users.length, false);
            for (int i = 0; i < users.length; i++) {
              if (friendRequests.any(
                  (request) => request['sender_email'] == users[i]['email'])) {
                isFriendAdded[i] = true;
              } else if (users[i]['status'] == '0' ||
                  users[i]['status'] == '2') {
                isFriendAdded[i] = true;
              }
            }
          }
        });
      } else {
        print('No users found');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> addFriend(String receiveEmail) async {
    try {
      String url = '${MyIp().domain}:3000/addfriend';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_email': widget.email,
          'receive_email': receiveEmail, // ตรวจสอบที่นี่
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Add Friends successfully');
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Add Friends failed');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> viewFriendRequests() async {
    try {
      String url =
          '${MyIp().domain}:3000/getfriendsrequest?email=${widget.email}';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        var responseData = jsonDecode(res.body);
        print(responseData);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            friendRequests = responseData['data'];
          });
        } else {
          print('No friend requests found');
        }
      } else {
        print('Failed to fetch friend requests: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> acceptFriend(String emailfriends, String addId) async {
    try {
      String url = '${MyIp().domain}:3000/acceptfriends';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'email_friends': emailfriends,
          'add_id': addId
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Accept Friends successfully');
      } else {
        Fluttertoast.showToast(msg: 'Accept Friends failed');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> rejectFriend(String addId, String emailfriends) async {
    try {
      String url = '${MyIp().domain}:3000/rejectfriends';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'add_id': addId}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Reject Friends successfully');
      } else {
        Fluttertoast.showToast(msg: 'Reject Friends failed');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    viewUser();
    viewFriendRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Friends',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
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
                      if (filterUsers[index]['email'] == widget.email) {
                        return SizedBox.shrink();
                      }

                      final isRequestSent = friendRequests.any((req) =>
                          req['sender_email'] == filterUsers[index]['email']);
                      final request = friendRequests.firstWhere(
                        (req) =>
                            req['sender_email'] == filterUsers[index]['email'],
                        orElse: () => null,
                      );
                      final status = request != null ? request['status'] : null;

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
                        trailing: isRequestSent &&
                                (status != '1' && status != '2')
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      acceptFriend(
                                        filterUsers[index]['email'],
                                        request['add_id'].toString(),
                                      );
                                      viewUser();
                                      viewFriendRequests();
                                    },
                                    child: Text(
                                      'Accept',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      rejectFriend(
                                        request['add_id'].toString(),
                                        filterUsers[index]['email'],
                                      );
                                      viewUser();
                                      viewFriendRequests();
                                    },
                                    child: Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              )
                            : TextButton(
                                child: Text(
                                  // ใช้เงื่อนไขจาก status ของ friendRequests
                                  (request['status'] == '0')
                                      ? "Send Already"
                                      : (request['status'] == '1')
                                          ? "Rejected"
                                          : "Add", // เงื่อนไขอื่นแสดงปุ่ม "Add"
                                  style: TextStyle(
                                    color: (request['status'] == '2')
                                        ? Colors.grey
                                        : Colors.green, // ปรับสีปุ่มตามสถานะ
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  addFriend(filterUsers[index]['email']);
                                },
                              ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Profileother(
                                email: filterUsers[index]['email'],
                                emailCurrent: widget.email,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Divider(),
          Text(
            'Friend Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: friendRequests.isEmpty
                ? Center(child: Text('No friend requests'))
                : ListView.builder(
                    itemCount: friendRequests.length,
                    itemBuilder: (context, index) {
                      final status = friendRequests[index]['status'];
                      return status != '1'
                          ? ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[300],
                                backgroundImage: friendRequests[index]
                                            ['profile_image'] !=
                                        null
                                    ? NetworkImage(
                                        '${MyIp().domain}:3000/editimageprofile/${friendRequests[index]['profile_image']}')
                                    : null,
                                child: friendRequests[index]['profile_image'] ==
                                        null
                                    ? Text(
                                        friendRequests[index]['email'][0]
                                            .toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Text(friendRequests[index]['username'] ??
                                  'Unknown sender'),
                              trailing: status != '1' && status != '2'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            acceptFriend(
                                              friendRequests[index]
                                                  ['sender_email'],
                                              friendRequests[index]['add_id']
                                                  .toString(),
                                            );
                                            viewFriendRequests();
                                          },
                                          child: Text(
                                            'Accept',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            rejectFriend(
                                                friendRequests[index]['add_id']
                                                    .toString(),
                                                friendRequests[index]
                                                    ['sender_email']);
                                            viewFriendRequests();
                                          },
                                          child: Text(
                                            'Reject',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox.shrink(),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Profileother(
                                      email: friendRequests[index]
                                          ['sender_email'],
                                      emailCurrent: widget.email,
                                    ),
                                  ),
                                );
                              },
                            )
                          : null;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
