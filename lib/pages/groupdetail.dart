// ignore_for_file: unnecessary_null_comparison
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project/bottom_navigationbar/navigation_page.dart';
import 'package:project/pages/editgroup.dart';
import 'package:project/pages/group_chat.dart';
import 'package:project/pages/mapdetail.dart';
import 'package:project/pages/profileother.dart';
import 'package:project/screen/myip.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupDetailPage extends StatefulWidget {
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
  final String groupId;
  final String time;
  final String date;

  const GroupDetailPage(
      {super.key,
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
      required this.groupId,
      required this.time,
      required this.date});

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final TextEditingController commentController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> participants = [];
  Map<String, dynamic>? owner;
  bool canCheckIn = false;
  late bool isEnd;
  bool isUpdating = false;
  Timer? timer;
  DateTime? startTime;
  bool isCheckInEnabled = false;
  bool isCheckedIn = false;
  Duration timeLeft = Duration(hours: 1);
  // ignore: prefer_typing_uninitialized_variables
  var joinstatus;

  @override
  void initState() {
    super.initState();
    fetchComments();
    viewParticipants();
    getJoinStatus();
    viewOwner();
    checkUserLocation();
    isEnd = widget.groupstatus == '1';
    checkGroupStatus();
    startCountdown();
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
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const BottomNavigationPage()));
      } else {
        throw Exception('Failed to delete group');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
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

  Future<void> updatecomment(int comment_id, String newText) async {
    try {
      String url = '${MyIp().domain}:3000/editcomment';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment_id': comment_id, 'comment_text': newText}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        fetchComments();
      } else {
        throw Exception('Failed to update comment');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Failed to update comment.");
    }
  }

  void showEditCommentDialog(int commentId, String currentText) {
    editController.text = currentText;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Comment'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: 'Enter new comment'),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                updatecomment(commentId, editController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  Future<void> endgroup() async {
    try {
      String url = '${MyIp().domain}:3000/endgroup';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupcode': widget.groupCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          isEnd = true;
        });
      } else {
        Fluttertoast.showToast(msg: data['message']);
        print("Response body: ${res.body}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  Future<void> getJoinStatus() async {
    try {
      String url = '${MyIp().domain}:3000/fetchjoinstatus';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.emailCurrent,
          'groupcode': widget.groupCode,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          data['success'] &&
          data.containsKey('join_status')) {
        setState(() {
          joinstatus = data['join_status'];
        });
        print(joinstatus);
        print(widget.statusMessage);
        print('emailCurrent: ${widget.emailCurrent}');
      } else {
        print("Response body: ${res.body}");
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
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

  Future<void> updateCredits() async {
    {
      try {
        String url = '${MyIp().domain}:3000/updatecredits';
        var res = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'groupCode': widget.groupCode,
          }),
        );

        final data = jsonDecode(res.body);

        if (res.statusCode == 200 && data['success']) {
          Fluttertoast.showToast(msg: data['message']);
        } else {
          Fluttertoast.showToast(msg: data['message']);
          print("Response body: ${res.body}");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "An error occurred. Please try again.");
      }
    }
  }

  Future<void> checkin() async {
    try {
      String url = '${MyIp().domain}:3000/checkin';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': widget.emailCurrent, 'groupCode': widget.groupCode}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          isCheckedIn = true;
          viewOwner();
          viewParticipants();
        });
      } else {
        Fluttertoast.showToast(msg: data['message']);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
    }
  }

  Future<void> checkUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      bool isInRadius = inRadius(
        position.latitude,
        position.longitude,
        double.parse(widget.latitude),
        double.parse(widget.longitude),
        500,
      );
      if (mounted) {
        setState(() {
          canCheckIn = isInRadius;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> endAndRefresh() async {
    setState(() {
      isUpdating = true;
    });

    await endgroup();
    await updateCredits();

    setState(() {
      isUpdating = false;
    });
  }

  bool inRadius(double userLat, double userLng, double targetLat,
      double targetLng, double radius) {
    const double earthRadius = 6371000;
    double dLat = (targetLat - userLat) * (pi / 180);
    double dLng = (targetLng - userLng) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180)) *
            cos(targetLat * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance <= radius;
  }

  Future<void> checkGroupStatus() async {
    try {
      String url = '${MyIp().domain}:3000/checkgroupstatus';

      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupCode': widget.groupCode}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          String groupStatus = data['groupStatus'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool hasRated = prefs.getBool(
                  'hasRate_${widget.groupCode}_${widget.emailCurrent}') ??
              false;

          if (groupStatus == '1' &&
              !hasRated &&
              widget.emailCurrent != widget.emailOwner &&
              joinstatus == '1') {
            ratingCreator();
          } else if (hasRated) {
            Fluttertoast.showToast(msg: 'You Already Rated this Group');
          }
        } else {
          Fluttertoast.showToast(msg: data['message']);
        }
      } else {
        Fluttertoast.showToast(msg: "Cannot connect to server");
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
    }
  }

  Future<void> submitRating(double rating) async {
    try {
      String url = '${MyIp().domain}:3000/submitrating';
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupCode': widget.groupCode, 'rating': rating}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(
              'hasRate_${widget.groupCode}_${widget.emailCurrent}', true);

          Fluttertoast.showToast(msg: 'Rating submitted successfully!');
        } else {
          Fluttertoast.showToast(msg: data['message']);
        }
      } else {
        Fluttertoast.showToast(msg: "Cannot connect to server");
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
    }
  }

  void ratingCreator() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double rating = 0;
        return AlertDialog(
          title: Text('Rate the Creator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please rate the creator of this activity:'),
              SizedBox(height: 20),
              RatingBar.builder(
                initialRating: rating,
                minRating: 0.5,
                maxRating: 5,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop();
                submitRating(rating);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> startCountdown() async {
    final startTime = await getTimestart(widget.groupCode);
    if (startTime != null) {
      final checkInStartTime = startTime.add(Duration(hours: 1));
      final now = DateTime.now();

      timeLeft = checkInStartTime.difference(now);

      if (timeLeft.inSeconds > 0) {
        timer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              if (timeLeft.inSeconds > 0) {
                timeLeft -= Duration(seconds: 1);
              } else {
                isCheckInEnabled = true;
                timeLeft = Duration.zero;
                timer.cancel();
              }
            });
          }
        });
      } else {
        setState(() {
          isCheckInEnabled = true;
          timeLeft = Duration.zero;
        });
      }
    } else {
      Fluttertoast.showToast(msg: "Cannot fetch Starttime");
    }
  }

  Future<DateTime?> getTimestart(String groupCode) async {
    try {
      String url = '${MyIp().domain}:3000/gettimestart';
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupCode': groupCode}),
      );

      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final timeString = data['time'];
        final dateString = data['date'];

        if (timeString == null || dateString == null) {
          print('Time or date is null');
          return null;
        }

        final dateFormat = DateFormat('dd/MM/yyyy');
        DateTime date = dateFormat.parse(dateString);

        final hour = int.parse(timeString.split(':')[0]);
        final minute = int.parse(timeString.split(':')[1].split(' ')[0]);
        final isPM = timeString.contains('PM');

        final adjustedHour =
            isPM && hour != 12 ? hour + 12 : (hour == 12 ? 0 : hour);

        final dateTime =
            DateTime(date.year, date.month, date.day, adjustedHour, minute);

        return dateTime;
      } else {
        final data = jsonDecode(res.body);
        print('Error: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('Error fetching start time: $e');
      return null;
    }
  }

  Future<void> cancelGroup(String groupCode, String reason) async {
    final response = await http.post(
      Uri.parse('${MyIp().domain}:3000/canclegroup'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'groupCode': groupCode,
        'reason': reason,
        'email': widget.emailCurrent
      }),
    );
    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Group canceled successfully.');
    } else {
      print('Failed to cancel group: ${response.body}');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
          if (widget.emailCurrent == widget.emailOwner &&
              widget.statusMessage == 'กิจกรรมยังไม่เริ่ม')
            TextButton(
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String? selectedReason;
                    String? otherReason;
                    List<String> reasons = ['ป่วย', 'ติดธุระ', 'อื่นๆ'];

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text("Confirm Cancel"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Please Select Reason"),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: selectedReason,
                                hint: Text("Select Reason"),
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
                                      otherReason = null;
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
                                  decoration: InputDecoration(
                                    hintText: "Please specify the reason",
                                  ),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Confirm",
                                  style: TextStyle(color: Colors.green)),
                              onPressed: () {
                                if (selectedReason != null &&
                                    (selectedReason != 'อื่นๆ' ||
                                        (selectedReason == 'อื่นๆ' &&
                                            otherReason != null &&
                                            otherReason!.isNotEmpty))) {
                                  final reason = selectedReason == 'อื่นๆ'
                                      ? otherReason!
                                      : selectedReason!;

                                  cancelGroup(widget.groupCode, reason);

                                  Navigator.of(context).pop();
                                  Navigator.pop(context);
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Please select a reason ",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          if (widget.emailCurrent == widget.emailOwner &&
              widget.statusMessage != 'กิจกรรมกำลังดำเนินการ' &&
              widget.statusMessage != 'กิจกรรมสิ้นสุด' &&
              widget.statusMessage != 'กิจกรรมยกเลิก')
            TextButton(
              child: Text(
                'Edit',
                style:
                    TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Edit_Group(groupCode: widget.groupCode),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
            ),
          if (widget.emailCurrent == widget.emailOwner &&
              !isEnd &&
              widget.statusMessage == 'กิจกรรมกำลังดำเนินการ' &&
              isCheckInEnabled &&
              widget.statusMessage != 'กิจกรรมยกเลิก')
            TextButton(
              child: Text(
                "End",
                style:
                    TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm End Group'),
                      content: Text('Are you sure you want to end this group?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Yes'),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await endAndRefresh();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (widget.emailCurrent == widget.emailOwner)
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
          if (joinstatus != null && widget.statusMessage != 'กิจกรรมยกเลิก')
            IconButton(
              icon: Icon(
                Icons.chat,
                color: Colors.pink,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChat(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      emailCurrent: widget.emailCurrent,
                      imagePath: widget.imagePath,
                    ),
                  ),
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
              trailing: Text(
                owner?['join_status'] == '1' ? 'มา' : 'ไม่มา',
                style: TextStyle(
                  color:
                      owner?['join_status'] == '1' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profileother(
                      email: owner?['email'],
                      emailCurrent: widget.emailCurrent,
                    ),
                  ),
                );
              },
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profileother(
                        email: participant['email_member'],
                        emailCurrent: widget.emailCurrent,
                      ),
                    ),
                  );
                },
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
            Text(
              'Date :${widget.date}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Time :${widget.time}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapDetail(
                      latitude: double.parse(widget.latitude),
                      longitude: double.parse(widget.longitude),
                      placeName: widget.nameplace,
                      email: widget.emailCurrent,
                      groupstatus: widget.groupstatus,
                      joinStatus: joinstatus,
                      statusMessage: widget.statusMessage,
                      grouCode: widget.groupCode,
                    ),
                  ),
                );
              },
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canCheckIn &&
                    widget.groupstatus != '1' &&
                    joinstatus != '1' &&
                    widget.statusMessage == 'กิจกรรมกำลังดำเนินการ' &&
                    !isCheckedIn &&
                    joinstatus != null &&
                    timeLeft.inSeconds > 0) // เพิ่มเงื่อนไขที่นี่
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.pink,
                        minimumSize: Size(100, 30),
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      ),
                      onPressed: () {
                        checkin();
                      },
                      child: Text(
                        'Check-In',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                if (canCheckIn &&
                    widget.groupstatus != '1' &&
                    joinstatus != '1' &&
                    widget.statusMessage == 'กิจกรรมกำลังดำเนินการ' &&
                    !isCheckedIn &&
                    joinstatus != null &&
                    timeLeft.inSeconds > 0)
                  Text(
                    'Time Left: ${timeLeft.inMinutes}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')} นาที',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
                                          ? comment['username'][0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12.0),
                                    )
                                  : null,
                            ),
                            title: Text(
                              comment != null && comment['username'] != null
                                  ? comment['username']
                                  : 'Unknown User',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.bold),
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
                                      ? timeAgo(
                                          DateTime.parse(comment['timestamp']))
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: widget.emailCurrent == comment?['email']
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            size: 18.0, color: Colors.grey),
                                        onPressed: () {
                                          if (comment != null) {
                                            showEditCommentDialog(
                                              comment['comment_id'],
                                              comment['comment_text'],
                                            );
                                          }
                                        },
                                      ),
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
                                  )
                                : null,
                          ),
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
