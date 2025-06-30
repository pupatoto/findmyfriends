import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/pages/direct_chat.dart';
import 'package:project/pages/group_chat.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/user.dart';
import 'package:project/screen/myip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var finalEmail;
  List<Map<String, dynamic>> group = [];
  List<Map<String, dynamic>> privateChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getData();
  }

  Future<void> getData() async {
    await getShared();
    await viewJoinGroup();
    await getUserStatus();
    await checkTimeoutStatus();
    await fetchPrivateChats();
  }

  Future<void> getShared() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      finalEmail = sharedPreferences.getString('email');
      print("SharedPreferences Email: $finalEmail");
    });
  }

  Future<void> viewJoinGroup() async {
    try {
      String url = '${MyIp().domain}:3000/groupjoinchat';
      var res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': finalEmail}),
          )
          .timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          group = List<Map<String, dynamic>>.from(data['groups']);
          print('join: $group');
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

  Future<void> fetchPrivateChats() async {
    try {
      String url = '${MyIp().domain}:3000/getChatFriends/?email=$finalEmail';
      var response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          privateChats = List<Map<String, dynamic>>.from(data);
          print('Private Chats: $privateChats');
        });
      } else {
        print('Failed to load private chats: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching private chats: $e");
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
          content: const Text('Your account has been timed out'),
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHAT',
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Group Chat'),
            Tab(text: 'Direct Chat'),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildGroupChatView(),
          buildPrivateChatView(),
        ],
      ),
    );
  }

  Widget buildGroupChatView() {
    return group.isEmpty
        ? const Center(
            child: Text('No groups found',
                style: TextStyle(fontSize: 18, color: Colors.grey)))
        : ListView.builder(
            itemCount: group.length,
            itemBuilder: (context, index) {
              return buildGroupTile(index);
            },
          );
  }

  Widget buildGroupTile(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.purple[300],
            backgroundImage: (group[index]['image_path'] is List
                ? NetworkImage(
                    '${MyIp().domain}:3000/postgroup/${group[index]['image_path'][0]}')
                : NetworkImage(
                    '${MyIp().domain}:3000/postgroup/${group[index]['image_path']}'))),
        title: Text(
          group[index]['group_name'],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${group[index]['sender_email'] == finalEmail ? 'You' : group[index]['sender_username']}: "
          "${group[index]['message_type'] == 'image' ? 'Sent image' : group[index]['latest_message']}",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        trailing: group[index]['latest_time'] != null
            ? Text(
                () {
                  try {
                    final dateTime =
                        DateTime.parse(group[index]['latest_time']);
                    return DateFormat('HH:mm').format(dateTime.toLocal());
                  } catch (e) {
                    print(
                        'Invalid date format: ${group[index]['latest_time']}');
                    return 'Invalid time';
                  }
                }(),
                style: const TextStyle(color: Colors.grey),
              )
            : const Text(
                'No time',
                style: TextStyle(color: Colors.grey),
              ),
        onTap: () {
          List<String> imagePath = (group[index]['image_path'] is List)
              ? List<String>.from(group[index]['image_path'])
              : [group[index]['image_path']];
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GroupChat(
                      groupId: group[index]['id_group'].toString(),
                      groupName: group[index]['group_name'],
                      emailCurrent: finalEmail,
                      groupStatus: group[index]['group_status'],
                      imagePath: imagePath))).then((_) {
            viewJoinGroup();
          });
        },
      ),
    );
  }

  Widget buildPrivateChatView() {
    return privateChats.isEmpty
        ? const Center(
            child: Text('No private chats found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          )
        : ListView.builder(
            itemCount: privateChats.length,
            itemBuilder: (context, index) {
              return buildPrivateChatTile(index);
            },
          );
  }

  Widget buildPrivateChatTile(int index) {
    String lastSender = privateChats[index]['last_sender'];
    bool isSelf = lastSender == finalEmail;

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink,
            backgroundImage: privateChats[index]['profile_image'] != null
                ? NetworkImage(
                    '${MyIp().domain}:3000/editimageprofile/${privateChats[index]['profile_image']}')
                : null,
            child: privateChats[index]['profile_image'] == null
                ? Text(
                    privateChats[index]['email'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            privateChats[index]['username'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          subtitle: Text(
            isSelf
                ? 'You: ${privateChats[index]['message_type'] == 'image' ? 'Sent an image' : privateChats[index]['last_message'] ?? 'No recent messages'}'
                : '${privateChats[index]['message_type'] == 'image' ? 'Sent an image' : privateChats[index]['last_message'] ?? 'No recent messages'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: privateChats[index]['time'] != null
              ? Text(
                  () {
                    try {
                      final dateTime =
                          DateTime.parse(privateChats[index]['time']);
                      return DateFormat('HH:mm').format(dateTime.toLocal());
                    } catch (e) {
                      print(
                          'Invalid date format: ${privateChats[index]['time']}');
                      return 'Invalid time';
                    }
                  }(),
                  style: const TextStyle(color: Colors.grey),
                )
              : const Text(
                  'No time',
                  style: TextStyle(color: Colors.grey),
                ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DirectChat(
                  reciveEmail: privateChats[index]['email'],
                  senderEmail: finalEmail,
                  imagePath: privateChats[index]['profile_image'] ?? '',
                  username: privateChats[index]['username'],
                ),
              ),
            ).then((_) {
              fetchPrivateChats();
            });
          },
        ));
  }
}
