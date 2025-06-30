// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/friendsadd.dart';
import 'package:project/pages/groupdetail.dart';
import 'package:project/pages/home.dart';
import 'package:project/pages/notifications.dart';
import 'package:project/pages/postgroup.dart';
import 'package:project/pages/user.dart';
import 'package:project/screen/myip.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> userGroups = [];
  List<Map<String, dynamic>> filterGroups = [];
  bool isLoading = true;
  String errorMessage = '';
  var finalEmail;
  Map<String, bool> groupJoinStatus = {};
  Map<String, bool> groupLikeStatus = {};
  String selectedGroupType = 'All';
  int notificationCount = 0;
  int friendRequestCount = 0;
  bool hasReported = false;
  LatLng? selectedLocation;
  String? selectedPlacename;
  TextEditingController locationController = TextEditingController();
  List<String> groupTypes = [
    "All",
    "Sport",
    "Music",
    "Education",
    "Volunteer",
    "Event",
    "Food"
  ];
  List<String> provinces = [
    'กรุงเทพมหานคร',
    'กระบี่',
    'กาญจนบุรี',
    'กาฬสินธุ์',
    'กำแพงเพชร',
    'ขอนแก่น',
    'จันทบุรี',
    'ฉะเชิงเทรา',
    'ชลบุรี',
    'ชัยนาท',
    'ชัยภูมิ',
    'ชุมพร',
    'เชียงใหม่',
    'เชียงราย',
    'ตรัง',
    'ตราด',
    'ตาก',
    'นครนายก',
    'นครปฐม',
    'นครพนม',
    'นครราชสีมา',
    'นครศรีธรรมราช',
    'นครสวรรค์',
    'นนทบุรี',
    'นราธิวาส',
    'น่าน',
    'บึงกาฬ',
    'บุรีรัมย์',
    'ปทุมธานี',
    'ประจวบคีรีขันธ์',
    'ปราจีนบุรี',
    'ปัตตานี',
    'พระนครศรีอยุธยา',
    'พะเยา',
    'พังงา',
    'พัทลุง',
    'พิจิตร',
    'พิษณุโลก',
    'เพชรบุรี',
    'เพชรบูรณ์',
    'แพร่',
    'ภูเก็ต',
    'มหาสารคาม',
    'มุกดาหาร',
    'แม่ฮ่องสอน',
    'ยโสธร',
    'ยะลา',
    'ร้อยเอ็ด',
    'ระนอง',
    'ระยอง',
    'ราชบุรี',
    'ลพบุรี',
    'ลำปาง',
    'ลำพูน',
    'เลย',
    'ศรีสะเกษ',
    'สกลนคร',
    'สงขลา',
    'สตูล',
    'สมุทรปราการ',
    'สมุทรสงคราม',
    'สมุทรสาคร',
    'สระบุรี',
    'สระแก้ว',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ'
  ];

  RangeValues rangeAge = RangeValues(15.0, 100.0);
  String? selectedProvince = 'กรุงเทพมหานคร';
  Map<String, bool> genderOptions = {
    'Male': true,
    'Female': true,
    'LGBTQ': true,
  };

  Future<void> toggleGroupStatus(
    String groupName,
    String emailOwner,
    String groupType,
    String groupCode,
  ) async {
    if (finalEmail == null) {
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
          'email_member': finalEmail,
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
            groupCode, groupJoinStatus[groupCode]!, finalEmail!);
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'An error occurred');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> toggleLikeStatus(String groupCode) async {
    if (finalEmail == null) {
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
          'email_like': finalEmail,
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
            groupCode, groupLikeStatus[groupCode]!, finalEmail!);
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
      userGroups.forEach((group) {
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
      userGroups.forEach((group) {
        String code = group['group_code'];
        groupLikeStatus[code] = prefs.getBool('like_${email}_$code') ?? false;
      });
    });
  }

  Future<void> getShared() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      finalEmail = sharedPreferences.getString('email');
      print("SharedPreferences Email: $finalEmail");
    });
  }

  Future<void> getData() async {
    await getShared();
    await viewGroup();
    await fetchNotificationCount();
    await viewFriendRequestsCount();
    await getUserStatus();
    await checkTimeoutStatus();
    filterGroupsByConditions();
  }

  Future<void> viewGroup() async {
    try {
      String url = '${MyIp().domain}:3000/viewgroup';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          userGroups = List<Map<String, dynamic>>.from(data['userGroups']);
          isLoading = false;
        });
        if (finalEmail != null) {
          await loadGroupJoinStatus(finalEmail!);
          await loadGroupLikeStatus(finalEmail!);
        }
      } else if (res.statusCode == 404) {
        setState(() {
          userGroups = [];
          isLoading = false;
          errorMessage = 'User is not a member of any group';
        });
      } else {
        throw Exception('Failed to load group data: ${res.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchNotificationCount() async {
    try {
      var response = await http.get(
        Uri.parse('${MyIp().domain}:3000/getnotifications?email=$finalEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notificationCount = data['notifications'].length;
        });
      } else {
        print('Failed to load notifications count');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> viewFriendRequestsCount() async {
    try {
      String url = '${MyIp().domain}:3000/getfriendsrequest?email=$finalEmail';
      var res = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        var responseData = jsonDecode(res.body);
        print(responseData);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            friendRequestCount = responseData['data']
                .where((request) => request['status'] == '0')
                .length;
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
      statusColor = Colors.grey; //
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

  Future<void> reportGroup(String grouCode) async {
    try {
      String url = '${MyIp().domain}:3000/reportgroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupCode': grouCode}),
      );
      var response = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          hasReported = true;
        });
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
  void initState() {
    super.initState();
    getData();
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
          content: const Text('Your account has been  timed out'),
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

  void filterGroupsByConditions() {
    setState(() {
      print('User Groups: $userGroups');
      print('Selected Province: $selectedProvince');
      print('Range Age: ${rangeAge.start}, ${rangeAge.end}');
      print('Gender Options: $genderOptions');
      print('Selected Group Type: $selectedGroupType');

      filterGroups = userGroups.where((group) {
        bool matchesProvince =
            selectedProvince == null || group['province'] == selectedProvince;

        double? minAge;
        double? maxAge;
        if (group['age'] != null && group['age'].toString().contains('-')) {
          List<String> ageRange = group['age'].toString().split('-');
          if (ageRange.length == 2) {
            try {
              minAge = double.parse(ageRange[0].trim());
              maxAge = double.parse(ageRange[1].trim());
            } catch (e) {
              minAge = null;
              maxAge = null;
            }
          }
        }

        bool matchesAge = minAge != null &&
            maxAge != null &&
            minAge <= rangeAge.end &&
            maxAge >= rangeAge.start;

        bool matchesGender = genderOptions.entries.any((entry) =>
            entry.value &&
            group['gender']?.split(',').contains(entry.key) == true);

        bool matchesGroupType = selectedGroupType == "All" ||
            (group['type_group'] == selectedGroupType);

        return matchesProvince &&
            matchesAge &&
            matchesGender &&
            matchesGroupType;
      }).toList();

      print('Filtered Groups: $filterGroups');
    });
  }

  void dialogCondition(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Conditions',
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Province',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: selectedProvince,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedProvince = newValue;
                          });
                        },
                        items: provinces.map((String province) {
                          return DropdownMenuItem<String>(
                            value: province,
                            child: Text(province),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Age Range: ${rangeAge.start.round()} - ${rangeAge.end.round()} years',
                            style: const TextStyle(fontSize: 16),
                          ),
                          RangeSlider(
                            values: rangeAge,
                            min: 15,
                            max: 100,
                            divisions: 85,
                            labels: RangeLabels(
                              rangeAge.start.round().toString(),
                              rangeAge.end.round().toString(),
                            ),
                            onChanged: (RangeValues values) {
                              setState(() {
                                rangeAge = values;
                              });
                            },
                            activeColor: Colors.pink,
                            inactiveColor: Colors.pink.shade100,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Wrap(
                            spacing: 10,
                            children: genderOptions.keys.map((gender) {
                              return ChoiceChip(
                                label: Text(gender),
                                selected: genderOptions[gender] ?? false,
                                selectedColor: Colors.pink,
                                backgroundColor: Colors.grey[200],
                                onSelected: (isSelected) {
                                  setState(() {
                                    genderOptions[gender] = isSelected;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Group Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: selectedGroupType,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGroupType = newValue!;
                          });
                        },
                        items: groupTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(
                'Confirm',
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                filterGroupsByConditions();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
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
            viewGroup();
            fetchNotificationCount();
            filterGroupsByConditions();
            viewFriendRequestsCount();
          },
          child: const Text(
            "HOME",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        foregroundColor: Colors.pink,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'Rules',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                    content: const Text(
                        '1. ประเภทกิจกรรมที่สร้างควรจะอยู่ในประเภทที่เหมาะสม.\n'
                        '2. การกดเข้าร่วมกิจกรรมควรพิจารณาให้ดีก่อน.\n'
                        '3. เมื่อเข้าร่วมกิจกรรมแล้วท่านต้องอยู่ภายในรัศมี 500 เมตรจากหมุดท่านถึงจะ Checkin ได้ \n'
                        '4. โดยมีระยะเวลเช็คอินได้ 1 ชั่วโมงนับตั้งแต่กิจกรรมเริ่ม\n'
                        '5. หากท่าน checkin ตามกำหนดเวลาได้ ท่านจะได้รับเพิ่ม 1 เครดิต\n'
                        '6. หากท่าน checkin ไม่ทันตามกำหนดเวลา ท่านจะโดนหัก 1 เตรดิต\n'
                        '7. หากท่านลบกลุ่มก่อนที่จะถึงเวลากิจกรรมท่านจะถูกลบเครดิต 2 เครดิค\n'
                        '8. หากท่านยกเลิกกิจกรรมท่านจะถูกหักเครดิต 1 เครดิต\n'
                        '9. หากท่านเครดิตเหลือ 0 ท่านจะถูกดำเนินการแบนโดยอัตโนมัติ \n'
                        '10. หากท่านพบกิจกรรมที่ไม่เหมาะสมกรุณารีพอร์ทมายังแอดมิน\n'
                        '11. กรุณาใช้ถ้อยคำที่เหมาะสมและไม่หยาบคาย'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Close',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              "Rule",
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Stack(
              children: <Widget>[
                const Icon(Icons.person_add),
                if (friendRequestCount > 0)
                  Positioned(
                    right: 0,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$friendRequestCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFriend(
                    email: finalEmail,
                  ),
                ),
              ).then((_) {
                viewFriendRequestsCount();
              });
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 10,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: 12,
                        maxHeight: 15,
                      ),
                      child: Center(
                        child: Text(
                          '$notificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Notifications_Page(emailCurrent: finalEmail),
                ),
              ).then((_) {
                fetchNotificationCount();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink[300],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Post_Group()),
          ).then((_) {
            viewGroup();
          });
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.pink[500],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 20),
                color: Colors.white,
                onPressed: () {
                  dialogCondition(context);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filterGroups.isEmpty
                    ? Center(child: Text(errorMessage))
                    : ListView.builder(
                        itemCount: filterGroups.length,
                        itemBuilder: (context, index) {
                          final allgroupsData = filterGroups[index];
                          final isJoined =
                              groupJoinStatus[allgroupsData['group_code']] ??
                                  false;
                          final isLiked =
                              groupLikeStatus[allgroupsData['group_code']] ??
                                  false;
                          List<String> imagePath = List<String>.from(
                              allgroupsData['image_path'] ?? []);
                          final iseventend = EventEndStatus(
                              allgroupsData['date'],
                              allgroupsData['time'],
                              allgroupsData['group_status']);
                          final participantCount =
                              allgroupsData['participant_count'] ?? 0;
                          final maxParticipants =
                              allgroupsData['max_participants'] ?? 0;
                          return Card(
                            margin: EdgeInsets.all(10),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ignore: unnecessary_null_comparison
                                    if (imagePath != null &&
                                        imagePath.isNotEmpty)
                                      SizedBox(
                                        height: 150,
                                        child: PageView.builder(
                                          itemCount: imagePath.length,
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(10)),
                                              child: Image.network(
                                                '${MyIp().domain}:3000/postgroup/${imagePath[index]}',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  print(
                                                      'Image loading error: $error');
                                                  return Container(
                                                    color: Colors.grey,
                                                    child: Center(
                                                      child: Text(
                                                          'Failed to load image'),
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
                                          allgroupsData['group_name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Type : ${allgroupsData['type_group']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Location : ${allgroupsData['placename']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Date : ${allgroupsData['date']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Time : ${allgroupsData['time']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Age : ${allgroupsData['age']}',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Gender : ${allgroupsData['gender']}',
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
                                              allgroupsData['group_status'] ??
                                                  '';

                                          String eventDate =
                                              allgroupsData['date'];
                                          String eventTime =
                                              allgroupsData['time'];

                                          if (groupStatus == '1') {
                                            statusMessage = 'กิจกรรมสิ้นสุด';
                                          } else if (groupStatus == '2') {
                                            statusMessage = 'กิจกรรมยกเลิก';
                                          } else if (EventEndStatus(eventDate,
                                              eventTime, groupStatus)) {
                                            statusMessage =
                                                'กิจกรรมกำลังดำเนินการ';
                                          } else {
                                            statusMessage =
                                                'กิจกรรมยังไม่เริ่ม';
                                          }

                                          print(statusMessage);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GroupDetailPage(
                                                groupName:
                                                    allgroupsData['group_name'],
                                                emailOwner: allgroupsData[
                                                    'email_owner'],
                                                typeGroup:
                                                    allgroupsData['type_group'],
                                                groupCode:
                                                    allgroupsData['group_code'],
                                                emailCurrent: finalEmail,
                                                nameplace:
                                                    allgroupsData['placename'],
                                                imagePath: imagePath,
                                                latitude:
                                                    allgroupsData['latitude'],
                                                longitude:
                                                    allgroupsData['longitude'],
                                                groupstatus: allgroupsData[
                                                    'group_status'],
                                                statusMessage: statusMessage,
                                                groupId:
                                                    allgroupsData['id_group']
                                                        .toString(),
                                                date: allgroupsData['date'],
                                                time: allgroupsData['time'],
                                              ),
                                            ),
                                          ).then((_) {
                                            viewGroup();
                                          });
                                        },
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (finalEmail !=
                                                allgroupsData['email_owner'])
                                              CircleAvatar(
                                                backgroundColor: Colors.white,
                                                child: IconButton(
                                                  iconSize: 16.0,
                                                  icon: Icon(
                                                    isLiked
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: isLiked
                                                        ? Colors.pink
                                                        : null,
                                                  ),
                                                  onPressed: () {
                                                    toggleLikeStatus(
                                                        allgroupsData[
                                                            'group_code']);
                                                  },
                                                ),
                                              ),
                                            SizedBox(width: 8.0),
                                            if (!iseventend)
                                              if (finalEmail !=
                                                  allgroupsData['email_owner'])
                                                CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  child: IconButton(
                                                    iconSize: 16.0,
                                                    icon: Icon(
                                                      isJoined
                                                          ? Icons.check
                                                          : Icons.add,
                                                      color: isJoined
                                                          ? Colors.green
                                                          : Colors.pink,
                                                    ),
                                                    onPressed: () {
                                                      // แสดงการยืนยัน
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(isJoined
                                                                ? 'Leave Group'
                                                                : 'Join Group'),
                                                            content: Text(isJoined
                                                                ? 'Are you sure you want to leave this group?'
                                                                : 'Are you sure you want to join this group?'),
                                                            actions: [
                                                              TextButton(
                                                                child: Text(
                                                                    'Cancel'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(); // ปิด dialog ถ้า cancel
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: Text(
                                                                    isJoined
                                                                        ? 'Leave'
                                                                        : 'Join'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(); // ปิด dialog ถ้า confirm
                                                                  // เรียกฟังก์ชัน toggleGroupStatus หลังจากยืนยัน
                                                                  toggleGroupStatus(
                                                                    allgroupsData[
                                                                        'group_name'],
                                                                    allgroupsData[
                                                                        'email_owner'],
                                                                    allgroupsData[
                                                                        'type_group'],
                                                                    allgroupsData[
                                                                        'group_code'],
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                        },
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: EventStatus(
                                          allgroupsData['date'],
                                          allgroupsData['time'],
                                          allgroupsData['group_status'],
                                        ),
                                      ),
                                      if (finalEmail !=
                                          allgroupsData['email_owner'])
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.black,
                                            size: 20.0,
                                          ),
                                          onSelected: (String value) {
                                            if (value == 'report') {
                                              reportGroup(
                                                  allgroupsData['group_code']);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              [
                                            const PopupMenuItem<String>(
                                              value: 'report',
                                              child: Text(
                                                'Report',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
