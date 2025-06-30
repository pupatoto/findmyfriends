import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/pages/profileother.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;

class Friendslist extends StatefulWidget {
  final String? email;

  const Friendslist({super.key, this.email});

  @override
  State<Friendslist> createState() => _FriendslistState();
}

class _FriendslistState extends State<Friendslist> {
  List<dynamic> friends = [];

  @override
  void initState() {
    super.initState();
    viewFriends();
  }

  Future<void> viewFriends() async {
    try {
      String url = '${MyIp().domain}:3000/getfriendslist?email=${widget.email}';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response['success'] == true) {
          setState(() {
            friends = response['friends'];
          });
        } else {
          print('Failed to fetch friends: ${response['message']}');
        }
      } else {
        print('Failed to fetch friends list: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
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
        viewFriends();
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to remove friend');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Friends List",
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          Text(
            'Friends ${friends.length} person   ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          )
        ],
      ),
      body: friends.isEmpty
          ? Center(child: Text("No friends found"))
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[300],
                        backgroundImage: friends[index]['profile_image'] != null
                            ? NetworkImage(
                                '${MyIp().domain}:3000/editimageprofile/${friends[index]['profile_image']}')
                            : null,
                        child: friends[index]['profile_image'] == null
                            ? Text(
                                friends[index]['email_friends'][0]
                                    .toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(
                        friends[index]['username'] ?? 'No Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: TextButton(
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
                                title: Text("Confirm Remove Friends"),
                                content: Text(
                                    "Are you sure you want to remove this friend?"),
                                actions: [
                                  TextButton(
                                    child: Text("Cancel",
                                        style: TextStyle(color: Colors.green)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      "Remove",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      removeFriends(
                                          friends[index]['email_friends']);
                                      Navigator.of(context).pop();
                                    },
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
                            builder: (context) => Profileother(
                              email: friends[index]['email_friends'],
                              emailCurrent: widget.email,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(),
                  ],
                );
              },
            ),
    );
  }
}
