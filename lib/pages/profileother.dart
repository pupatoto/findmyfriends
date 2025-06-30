import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project/pages/direct_chat.dart';
import 'package:project/pages/friendslistother.dart';
import 'package:project/pages/groupdetail.dart';
import 'package:project/screen/myip.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Profileother extends StatefulWidget {
  final String email;
  final String? emailCurrent;
  const Profileother({
    super.key,
    required this.email,
    required this.emailCurrent,
  });

  @override
  State<Profileother> createState() => _ProfileotherState();
}

class _ProfileotherState extends State<Profileother> {
  var username;
  var userid;
  var profileImage;
  var birthdate;
  String? age;
  var gender;
  var credit;
  String? friendRequestStatus;
  List<dynamic> friendRequests = [];
  bool isFriendRequestPending = false;
  List<dynamic> friends = [];
  String? addId;
  String ratingShow = "No review";
  Color? ratingColor;
  @override
  void initState() {
    super.initState();
    viewData();
    checkFriendStatus();
    viewFriendRequests();
    viewFriends();
    getCreatorCredits();
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
        });
        print(data);
        print(widget.email);
        print('emailCurrent :${widget.emailCurrent}');
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> checkFriendStatus() async {
    try {
      String url = '${MyIp().domain}:3000/checkfriendstatus';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_email': widget.emailCurrent,
          'receive_email': widget.email,
        }),
      );
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        print('Response data: $data');
        setState(() {
          friendRequestStatus = data['status'];
        });
        print('friendstatus: $friendRequestStatus');
      } else {
        print('Failed to check friend status');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> addFriend() async {
    try {
      String url = '${MyIp().domain}:3000/addfriend';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_email': widget.emailCurrent,
          'receive_email': widget.email,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend request sent successfully');
        setState(() {
          friendRequestStatus = '0';
        });
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
          'sender_email': widget.emailCurrent,
          'receive_email': receiveEmail,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend request removed successfully');
        setState(() {
          friendRequestStatus = null;
        });
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to remove friend request');
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
          'sender_email': widget.emailCurrent,
          'receive_email': receiveEmail,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Friend removed successfully');
        setState(() {
          friendRequestStatus = null;
        });
      } else {
        print("Response body: ${response.body}");
        Fluttertoast.showToast(msg: 'Failed to remove friend');
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> acceptFriend(String? emailfriends, String addId) async {
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

  Future<void> viewFriendRequests() async {
    try {
      String url =
          '${MyIp().domain}:3000/getfriendsrequest?email=${widget.emailCurrent}';
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

          // หาคำขอที่ sender_email ตรงกับ widget.email
          var myFriendRequests = friendRequests.where((request) {
            return request['sender_email'] == widget.email;
          }).toList();

          // คุณสามารถใช้ myFriendRequests เพื่อทำงานต่อได้
          print("My Friend Requests: $myFriendRequests");
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
          print('friends $friends');
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

  Future<void> getCreatorCredits() async {
    String url = '${MyIp().domain}:3000/getcreatorcredits';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User status: ${data['success']}');

        if (data['success']) {
          double averageRating = data['averageRating'] != null
              ? double.tryParse(data['averageRating'].toString()) ?? 0.0
              : 0.0;

          print('Average Rating: $averageRating');

          String ratingMessage;
          if (data['averageRating'] == null) {
            ratingMessage = 'No Review';
          } else {
            if (averageRating >= 0 && averageRating < 2) {
              ratingMessage = 'Bad Creator';
              ratingColor = Colors.red;
            } else if (averageRating >= 2 && averageRating < 4) {
              ratingMessage = 'Good Creator';
              ratingColor = Colors.amber;
            } else if (averageRating >= 4 && averageRating <= 5) {
              ratingMessage = 'Best Creator';
              ratingColor = Colors.green;
            } else {
              ratingMessage = 'Invalid Rating';
              ratingColor = Colors.grey;
            }
          }
          print('Rating Message: $ratingMessage');
          setState(() {
            ratingShow = ratingMessage;
            ratingColor = ratingColor;
          });
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        print('Error retrieving user status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while calling API: $e');
    }
  }

  Future<void> reportUser(String email, String reason) async {
    try {
      String url = '${MyIp().domain}:3000/reportuser';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'messages': reason}),
      );
      var response = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {});
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            if (widget.emailCurrent != widget.email)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String? selectedReason;
                      String? otherReason;
                      List<String> reasons = [
                        'การละเมิดกฎ',
                        'พฤติกรรมไม่เหมาะสม',
                        'อื่นๆ'
                      ];

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Report User'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Please select a reason:"),
                                DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedReason,
                                  hint: const Text("Select Reason"),
                                  items: reasons.map((String reason) {
                                    return DropdownMenuItem<String>(
                                      value: reason,
                                      child: Text(reason),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedReason = newValue;
                                      if (selectedReason != 'อื่นๆ') {
                                        otherReason =
                                            null; // reset if not 'other'
                                      }
                                    });
                                  },
                                ),
                                if (selectedReason == 'อื่นๆ')
                                  TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        otherReason = value;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Please specify the reason",
                                    ),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (selectedReason != null &&
                                      (selectedReason != 'อื่นๆ' ||
                                          (selectedReason == 'อื่นๆ' &&
                                              otherReason != null &&
                                              otherReason!.isNotEmpty))) {
                                    final reason = selectedReason == 'อื่นๆ'
                                        ? otherReason!
                                        : selectedReason!;
                                    reportUser(widget.email, reason);
                                    Navigator.of(context).pop();
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Please select a reason",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                    );
                                  }
                                },
                                child: Text(
                                  'Submit',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text(
                  'Report',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            if (friendRequestStatus == '2')
              IconButton(
                icon: const Icon(
                  Icons.message,
                  color: Colors.pink,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DirectChat(
                              senderEmail: widget.emailCurrent,
                              reciveEmail: widget.email,
                              imagePath: profileImage ?? '',
                              username: username,
                            )),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      ratingShow,
                      style: TextStyle(
                        color: ratingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Friendslistother(
                              email: widget.email,
                              emailCurent: widget.emailCurrent,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Friends ${friends.length} person",
                        style: const TextStyle(
                          color: Colors.pink,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            if (widget.emailCurrent != widget.email) ...[
              if (friendRequestStatus == null ||
                  friendRequestStatus == '1') ...[
                ElevatedButton(
                  onPressed: () {
                    addFriend();
                  },
                  child: Text(
                    'Add Friend',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ] else if (friendRequestStatus == '0') ...[
                if (friendRequests.any(
                    (request) => request['sender_email'] == widget.email)) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          var request = friendRequests.firstWhere(
                              (req) => req['sender_email'] == widget.email);
                          acceptFriend(widget.emailCurrent,
                              request['add_id'].toString());
                          setState(() {
                            friendRequestStatus = '2';
                          });
                        },
                        child: Text(
                          'Accept',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          var request = friendRequests.firstWhere(
                              (req) => req['sender_email'] == widget.email);
                          rejectFriend(
                              widget.email,
                              request['add_id']
                                  .toString()); // ใช้ addid จาก request
                          setState(() {
                            friendRequestStatus =
                                '1'; // เปลี่ยนสถานะเป็นปฏิเสธหลังจากกด Reject
                          });
                        },
                        child: Text(
                          'Reject',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // แสดงปุ่ม Remove Request เมื่อ friendRequestStatus == '0' แต่ email เป็นผู้รับคำขอ
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm Remove"),
                            content: Text(
                                "Are you sure you want to remove request?"),
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
                                  removeaddFriends(widget.email);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      'Remove Request',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ] else if (friendRequestStatus == '2') ...[
                // แสดงปุ่ม Remove Friend เมื่อสถานะเป็นเพื่อนแล้ว
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirm Remove Friend"),
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
                                removeFriends(widget.email);
                                setState(() {
                                  friendRequestStatus = null; // รีเซ็ตสถานะ
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    'Remove Friend',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
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
                    emailCurrent: widget.emailCurrent,
                  ),
                  ParticipateView(
                    email: widget.email,
                    emailCurrent: widget.emailCurrent,
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
          groupJoinStatus[groupCode] = !groupJoinStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupJoinStatus[groupCode]!
                ? 'Successfully joined the group'
                : 'Successfully left the group');

        await saveGroupJoinStatus(
            groupCode, groupJoinStatus[groupCode]!, widget.emailCurrent!);
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
          groupLikeStatus[groupCode] = !groupLikeStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupLikeStatus[groupCode]!
                ? 'Successfully liked the group'
                : 'Successfully unliked the group');

        await saveGroupLikeStatus(
            groupCode, groupLikeStatus[groupCode]!, widget.emailCurrent!);
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
      group.forEach((group) {
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
      group.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] = prefs.getBool('like_${email}_$code') ?? false;
      });
    });
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
        await loadGroupJoinStatus(widget.emailCurrent!);
        await loadGroupLikeStatus(widget.emailCurrent!);
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
    if (groupStatus == '1' || groupStatus == '2') {
      return true; // หากเป็น '1' หรือ '2' ให้คืนค่า true เพื่อบ่งบอกว่าสิ้นสุดแล้ว
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
      statusColor = Colors.grey; // สีสำหรับสถานะยกเลิก
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
                final isJoined =
                    groupJoinStatus[groupPost['group_code']] ?? false;
                final isLiked =
                    groupLikeStatus[groupPost['group_code']] ?? false;
                final iseventend = EventEndStatus(groupPost['date'],
                    groupPost['time'], groupPost['group_status']);
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.emailCurrent !=
                                      groupPost['email_owner'])
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
                                              groupPost['group_code']);
                                        },
                                      ),
                                    ),
                                  SizedBox(width: 8.0),
                                  if (!iseventend)
                                    if (widget.emailCurrent !=
                                        groupPost['email_owner'])
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
                                              groupPost['group_name'],
                                              groupPost['email_owner'],
                                              groupPost['type_group'],
                                              groupPost['group_code'],
                                            );
                                          },
                                        ),
                                      )
                                ],
                              ),
                              onTap: () {
                                String statusMessage;
                                String groupStatus =
                                    groupPost['group_status'] ?? '';

                                String eventDate = groupPost['date'];
                                String eventTime = groupPost['time'];

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
                                    builder: (context) => GroupDetailPage(
                                      groupName: groupPost['group_name'],
                                      emailOwner: groupPost['email_owner'],
                                      typeGroup: groupPost['type_group'],
                                      groupCode: groupPost['group_code'],
                                      emailCurrent: widget.emailCurrent,
                                      nameplace: groupPost['placename'],
                                      imagePath: imagePath,
                                      latitude: groupPost['latitude'],
                                      longitude: groupPost['longitude'],
                                      groupstatus: groupPost['group_status'],
                                      statusMessage: statusMessage,
                                      groupId: groupPost['id_group'].toString(),
                                      date: groupPost['date'],
                                      time: groupPost['time'],
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
        await loadGroupJoinStatus(widget.emailCurrent!);
        await loadGroupLikeStatus(widget.emailCurrent!);
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
          groupJoinStatus[groupCode] = !groupJoinStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupJoinStatus[groupCode]!
                ? 'Successfully joined the group'
                : 'Successfully left the group');

        await saveGroupJoinStatus(
            groupCode, groupJoinStatus[groupCode]!, widget.emailCurrent!);
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
          groupLikeStatus[groupCode] = !groupLikeStatus[groupCode]!;
        });

        Fluttertoast.showToast(
            msg: groupLikeStatus[groupCode]!
                ? 'Successfully liked the group'
                : 'Successfully unliked the group');

        await saveGroupLikeStatus(
            groupCode, groupLikeStatus[groupCode]!, widget.emailCurrent!);
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
      group.forEach((group) {
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
      group.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] = prefs.getBool('like_${email}_$code') ?? false;
      });
    });
  }

  bool EventEndStatus(String eventDate, String eventTime, String groupStatus) {
    DateFormat dateFormat = DateFormat('d/M/yyyy h:mm a');
    DateTime now = DateTime.now();
    DateTime eventDateTime = dateFormat.parse('$eventDate $eventTime');
    if (groupStatus == '1' || groupStatus == '2') {
      return true; // หากเป็น '1' หรือ '2' ให้คืนค่า true เพื่อบ่งบอกว่าสิ้นสุดแล้ว
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
      statusColor = Colors.grey; // สีสำหรับสถานะยกเลิก
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                                String groupStatus =
                                    groupjoin['group_status'] ?? '';

                                String eventDate = groupjoin['date'];
                                String eventTime = groupjoin['time'];

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
                                    builder: (context) => GroupDetailPage(
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
                                  if (widget.emailCurrent !=
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
                                    if (widget.emailCurrent !=
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
