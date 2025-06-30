import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/pages/editProfileimge.dart';
import 'package:project/pages/edit_profile.dart';
import 'package:project/pages/friendslist.dart';
import 'package:project/pages/groupdetail.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/likepages.dart';
import 'package:project/pages/user.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var finalEmail;
  var username;
  var userid;
  var profileImage;
  var birthdate;
  String? age;
  var gender;
  var credit;
  Color? ratingColor;
  List<dynamic> friends = [];
  String ratingShow = "No review";
  final GlobalKey<UserGroupsViewState> userGroupsKey =
      GlobalKey<UserGroupsViewState>();
  final GlobalKey<ParticipateViewState> userJoinKey =
      GlobalKey<ParticipateViewState>();

  Future<void> viewData() async {
    try {
      String url = '${MyIp().domain}:3000/currentuser';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': finalEmail}),
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
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  String normalizeGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) {
      return 'Other';
    }
    String normalizedGender = gender.trim().toLowerCase();
    if (normalizedGender == 'male') {
      return 'Male';
    } else if (normalizedGender == 'female') {
      return 'Female';
    } else {
      return 'LGBTQ';
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getShared() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      finalEmail = sharedPreferences.getString('email');
      print("SharedPreferences Email: $finalEmail");
    });

    if (finalEmail != null) {
      await viewData();
    } else {
      print("No email found in SharedPreferences");
    }
  }

  Future<void> getData() async {
    await getShared();
    if (finalEmail != null) {
      userGroupsKey.currentState?.viewPostGroup();
      userJoinKey.currentState?.viewJoinGroup();
      viewFriends();
      getUserStatus();
      checkTimeoutStatus();
      getCreatorCredits();
    }
  }

  Future<void> viewFriends() async {
    try {
      String url = '${MyIp().domain}:3000/getfriendslist?email=$finalEmail';
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

  Future<void> getUserStatus() async {
    if (finalEmail == null) {
      print('Email is null, cannot check user status');
      return;
    }

    String url = '${MyIp().domain}:3000/checkbanstatus';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': finalEmail}),
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

  Future<void> getCreatorCredits() async {
    String url = '${MyIp().domain}:3000/getcreatorcredits';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': finalEmail}),
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
            ratingColor = Colors.grey;
          } else {
            if (averageRating >= 0 && averageRating < 2) {
              ratingMessage = 'Bad Creator';
              ratingColor = Colors.red; // สีแดง
            } else if (averageRating >= 2 && averageRating < 4) {
              ratingMessage = 'Good Creator';
              ratingColor = Colors.amber; // สีเหลือง
            } else if (averageRating >= 4 && averageRating <= 5) {
              ratingMessage = 'Best Creator';
              ratingColor = Colors.green; // สีเขียว
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
          // ดำเนินการเพิ่มเติมถ้าจำเป็น เช่น แสดงผลข้อมูลใน UI
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
    if (finalEmail == null) {
      print('Email is null, cannot check timeout status');
      return;
    }

    String url = '${MyIp().domain}:3000/checktimeout';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': finalEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data'); // พิมพ์การตอบสนองทั้งหมด

        DateTime? timeoutUntil;
        if (data['timeoutUntil'] != null) {
          timeoutUntil = DateTime.parse(data[
              'timeoutUntil']); // ตรวจสอบให้แน่ใจว่าบรรทัดนี้จัดการกับ null
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              getData();
            },
            child: Text(
              "PROFILE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          foregroundColor: Colors.pink,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.favorite,
                color: Colors.pink,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LikePage(finalEmail: finalEmail),
                  ),
                );
              },
            ),
            TextButton(
              child: Text(
                "Edit Profile",
                style: TextStyle(color: Colors.pink),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => edit_profile(
                      userid.toString(),
                      username,
                      finalEmail,
                      birthdate ?? '',
                      normalizeGender(gender),
                      age?.toString() ?? '',
                    ),
                  ),
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
                            builder: (context) => Friendslist(
                              email: finalEmail,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Friends ${friends.length} person",
                        style: TextStyle(
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
                          finalEmail != null
                              ? finalEmail[0].toUpperCase()
                              : 'N/A',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileImage(
                            finalEmail: finalEmail ?? '',
                            userId: userid?.toString() ?? '',
                            profileImage: profileImage ?? '',
                          ),
                        ),
                      );
                      if (result == true) {
                        viewData();
                      }
                    },
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.grey[300],
                      child:
                          Icon(Icons.edit, size: 16, color: Colors.pinkAccent),
                    ),
                  ),
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
            const TabBar(
              indicatorColor: Colors.pink,
              labelColor: Colors.pink,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3.0,
              tabs: [
                Tab(text: "Your Post"),
                Tab(text: "Your Participate"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  UserGroupsView(key: userGroupsKey, email: finalEmail),
                  ParticipateView(key: userJoinKey, email: finalEmail),
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

  UserGroupsView({Key? key, this.email}) : super(key: key);

  @override
  UserGroupsViewState createState() => UserGroupsViewState();
}

class UserGroupsViewState extends State<UserGroupsView> {
  List<Map<String, dynamic>> group = [];

  @override
  void initState() {
    super.initState();
    viewPostGroup();
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
                                      emailCurrent: widget.email,
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
  ParticipateView({Key? key, this.email});
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
        if (widget.email != null) {
          await loadGroupJoinStatus(widget.email!);
          await loadGroupLikeStatus(widget.email!);
        }
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
            groupCode, groupJoinStatus[groupCode]!, widget.email!);
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
            groupCode, groupLikeStatus[groupCode]!, widget.email!);
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
                                      emailCurrent: widget.email,
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
                                  if (widget.email != groupjoin['email_owner'])
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
                                    if (widget.email !=
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
