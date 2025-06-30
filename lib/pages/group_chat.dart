import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:project/screen/myip.dart';
import 'package:intl/intl.dart';

class GroupChat extends StatefulWidget {
  final String groupId;
  final String? groupName;
  final String? emailCurrent;
  final String? groupStatus;
  final List<String>? imagePath;

  GroupChat(
      {Key? key,
      required this.groupId,
      this.groupName,
      this.emailCurrent,
      this.groupStatus,
      this.imagePath})
      : super(key: key);

  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  List messages = [];
  TextEditingController messagecontroller = TextEditingController();
  Timer? timer;
  ScrollController scrollController = ScrollController();
  bool isAtBottom = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(scrollListener);
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchMessages());
  }

  void scrollListener() {
    if (scrollController.position.atEdge) {
      isAtBottom = scrollController.position.pixels ==
          scrollController.position.maxScrollExtent;
    } else {
      isAtBottom = false;
    }
  }

  Future<void> fetchMessages() async {
    final response = await http.get(
      Uri.parse('${MyIp().domain}:3000/getmessages?groupId=${widget.groupId}'),
    );
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          messages = json.decode(response.body);
        });
        if (isAtBottom && scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
        }
      }
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<void> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('${MyIp().domain}:3000/sendmessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupId': widget.groupId,
        'sender': widget.emailCurrent,
        'message': message
      }),
    );
    if (response.statusCode == 201) {
      messagecontroller.clear();
      fetchMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      throw Exception('Failed to send message');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        List<File> images =
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
        await sendImage(images);
      } else {
        Fluttertoast.showToast(msg: "No images selected");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking images: $e");
    }
  }

  Future<void> sendImage(List<File> images) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${MyIp().domain}:3000/sendimage'),
    );
    request.fields['groupId'] = widget.groupId;
    request.fields['sender_email'] = widget.emailCurrent!;

    for (var image in images) {
      request.files
          .add(await http.MultipartFile.fromPath('sendimage', image.path));
    }

    var response = await request.send();
    if (response.statusCode == 201) {
      fetchMessages();
      Fluttertoast.showToast(msg: "Images sent successfully");
    } else {
      Fluttertoast.showToast(msg: "Failed to send images");
      throw Exception('Failed to send images');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await http.post(
      Uri.parse('${MyIp().domain}:3000/deletemessages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messagesId': messageId}),
    );

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Delete Message Success");
      fetchMessages();
    } else {
      Fluttertoast.showToast(msg: "Failed to delete message");
      throw Exception('Failed to delete message');
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
    scrollController.dispose();
  }

  void viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple[300],
              backgroundImage:
                  widget.imagePath != null && widget.imagePath!.isNotEmpty
                      ? NetworkImage(
                          '${MyIp().domain}:3000/postgroup/${widget.imagePath![0]}',
                        )
                      : null,
              child: widget.imagePath == null || widget.imagePath!.isEmpty
                  ? Text(
                      widget.groupName!.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            SizedBox(width: 20),
            Text(
              '${widget.groupName}',
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.image_sharp,
              color: Colors.pink,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageHistory(
                    groupId: widget.groupId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isCurrentUser =
                    messages[index]['sender_email'] == widget.emailCurrent;

                DateTime messageDate =
                    DateTime.parse(messages[index]['time']).toLocal();
                String formattedDate =
                    DateFormat('dd MMM yyyy').format(messageDate);
                String formattedTime = DateFormat('HH:mm').format(messageDate);

                bool isFirstMessageOfDay = index == 0 ||
                    DateFormat('yyyy-MM-dd').format(messageDate) !=
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(messages[index - 1]['time'])
                                .toLocal());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstMessageOfDay)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrentUser) ...[
                              CircleAvatar(
                                backgroundColor: Colors.purple[300],
                                backgroundImage: messages[index]
                                            ['profile_image'] !=
                                        null
                                    ? NetworkImage(
                                        '${MyIp().domain}:3000/editimageprofile/${messages[index]['profile_image']}')
                                    : null,
                                child: messages[index]['profile_image'] == null
                                    ? Text(
                                        messages[index]['sender_email'][0]
                                            .toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 1.0),
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isCurrentUser
                                        ? "You"
                                        : messages[index]['username'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser
                                          ? Colors.pink
                                          : Colors.black,
                                    ),
                                  ),
                                  GestureDetector(
                                    onLongPress: () async {
                                      if (widget.emailCurrent ==
                                          messages[index]['sender_email']) {
                                        bool? confirmDelete = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Delete Message"),
                                              content: Text(
                                                  "Are you sure you want to delete this message?"),
                                              actions: [
                                                TextButton(
                                                  child: Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(false);
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text("Delete"),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirmDelete == true) {
                                          deleteMessage(messages[index]
                                                  ['messagesg_id']
                                              .toString());
                                        }
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(top: 5),
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? Colors.pink[200]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomLeft: isCurrentUser
                                              ? Radius.circular(10)
                                              : Radius.circular(0),
                                          bottomRight: isCurrentUser
                                              ? Radius.circular(0)
                                              : Radius.circular(10),
                                        ),
                                      ),
                                      child: messages[index]['message_type'] ==
                                              'image'
                                          ? Column(
                                              children: List<Widget>.from(
                                                (messages[index]['imageurl']
                                                        as List<dynamic>)
                                                    .map(
                                                  (imageName) => Padding(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        bottom:
                                                            8.0), // ช่องว่างระหว่างแต่ละรูป
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        viewImage(
                                                            '${MyIp().domain}:3000/sendimage/$imageName');
                                                      },
                                                      child: Image.network(
                                                        '${MyIp().domain}:3000/sendimage/$imageName',
                                                        width: 200,
                                                        height: 200,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Text(messages[index]['message']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.groupStatus == '1')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "This group Already End.",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          else if (widget.groupStatus == '2')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "This group Cancle",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messagecontroller,
                      decoration: InputDecoration(labelText: 'Send a message'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.pink,
                    ),
                    onPressed: () {
                      if (messagecontroller.text.isNotEmpty) {
                        sendMessage(messagecontroller.text);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.image,
                      color: Colors.pink,
                    ),
                    onPressed: () {
                      pickImage(ImageSource.gallery);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.pink,
                    ),
                    onPressed: () {
                      pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Image',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class ImageHistory extends StatefulWidget {
  final String groupId;

  ImageHistory({required this.groupId});

  @override
  _ImageHistoryState createState() => _ImageHistoryState();
}

class _ImageHistoryState extends State<ImageHistory> {
  List<Map<String, dynamic>> images = [];

  @override
  void initState() {
    super.initState();
    getImagesHistory();
  }

  Future<void> getImagesHistory() async {
    try {
      final response = await http.post(
        Uri.parse('${MyIp().domain}:3000/historyimage'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'groupId': widget.groupId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ตรวจสอบว่า data['images'] มีข้อมูลหรือไม่
        if (data['images'] == null || data['images'].isEmpty) {
          setState(() {
            images = [];
          });
          return;
        }

        setState(() {
          images = List<Map<String, dynamic>>.from(data['images']);
          print('image: $images');
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to load images: ${errorData["message"]}');
      }
    } catch (error) {
      print("Error: $error");
      setState(() {
        images = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History Image',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
      ),
      body: images.isEmpty
          ? Center(child: Text('No images found.'))
          : ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                DateTime messageDate =
                    DateTime.parse(images[index]['time']).toLocal();
                String formattedDate =
                    DateFormat('dd MMM yyyy').format(messageDate);
                String formattedTime = DateFormat('HH:mm').format(messageDate);

                bool isFirstMessageOfDay = index == 0 ||
                    DateFormat('yyyy-MM-dd').format(messageDate) !=
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(images[index - 1]['time'])
                                .toLocal());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstMessageOfDay)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    Row(
                      children:
                          images[index]['imageurl'].map<Widget>((imageUrl) {
                        String fullImageUrl =
                            '${MyIp().domain}:3000/sendimage/$imageUrl';
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FullScreenImage(imageUrl: fullImageUrl),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
