import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/home.dart';
import 'package:project/pages/profileother.dart';
import 'package:project/pages/user.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFriend extends StatefulWidget {
  final String email;

  const AddFriend({Key? key, required this.email}) : super(key: key);

  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
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
              if (users[i]['status'] == '0' || users[i]['status'] == '2') {
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
          'receive_email': receiveEmail,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend request sent successfully');
        viewUser(); // Refresh the user list
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to send friend request');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> removeaddFriends(String receiveEmail) async {
    try {
      String url = '${MyIp().domain}:3000/removeaddfriend';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_email': widget.email,
          'receive_email': receiveEmail,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend request removed successfully');
        viewUser();
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to remove friend request');
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

  Future<void> removeFriends(String receiveEmail) async {
    try {
      String url = '${MyIp().domain}:3000/removefriends';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_email': widget.email,
          'receive_email': receiveEmail,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend removed successfully');
        viewUser();
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to remove friend');
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
    getUserStatus();
    checkTimeoutStatus();
  }

  Future<void> getUserStatus() async {
    String url = '${MyIp().domain}:3000/checkbanstatus';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
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
            title: const Text('Account Banned'),
            content:
                const Text('Your account has been banned. Please log out.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Logout'),
                onPressed: () async {
                  await User.setsignin(false);
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  await preferences.remove('email');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    String url = '${MyIp().domain}:3000/checktimeout';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
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
          title: const Text('Account Timeout'),
          content: const Text('Your account has been  timed out'),
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
        title: GestureDetector(
          onTap: () {
            setState(() {
              viewUser();
            });
          },
          child: Text(
            "Add Friends",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          ),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status == '0')
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await acceptFriend(
                                        filterUsers[index]['email'],
                                        request['add_id'].toString(),
                                      );
                                      viewFriendRequests();
                                      viewUser();
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
                                    onPressed: () async {
                                      await rejectFriend(
                                        request['add_id'].toString(),
                                        filterUsers[index]['email'],
                                      );
                                      viewFriendRequests();
                                      viewUser();
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
                            else if (filterUsers[index]['status'] == '2')
                              TextButton(
                                child: Text(
                                  "Friends",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirm Removal"),
                                        content: Text(
                                            "Are you sure you want to remove this friend?"),
                                        actions: [
                                          TextButton(
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text("Remove"),
                                            onPressed: () {
                                              removeFriends(
                                                  filterUsers[index]['email']);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              )
                            else if (isFriendAdded[index])
                              ElevatedButton(
                                onPressed: () async {
                                  await removeaddFriends(
                                      filterUsers[index]['email']);
                                },
                                child: Text(
                                  "Remove",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(color: Colors.red, width: 2),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () async {
                                  await addFriend(filterUsers[index]['email']);
                                },
                                child: Text(
                                  "Add",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  side:
                                      BorderSide(color: Colors.green, width: 2),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
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
                          ).then((_) {
                            viewUser();
                          });
                        },
                      );
                    },
                  ),
          ),
          Divider(),
          Text(
            'Friend Requests',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
          ),
          Expanded(
            child: friendRequests.isEmpty
                ? Center(child: Text('No friend requests'))
                : ListView.builder(
                    itemCount: friendRequests.length,
                    itemBuilder: (context, index) {
                      final status = friendRequests[index]['status'];
                      return status != '1' && status != '2'
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
                                        friendRequests[index]['sender_email'][0]
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
                                            viewUser();
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
                                            viewUser();
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
                                ).then((_) {
                                  viewUser();
                                  setState(() {});
                                });
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
