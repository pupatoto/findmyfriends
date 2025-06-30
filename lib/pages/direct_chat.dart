import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:project/pages/group_chat.dart';
import 'dart:convert';
import 'dart:async';
import 'package:project/screen/myip.dart';

class DirectChat extends StatefulWidget {
  final String reciveEmail;
  final String? senderEmail;
  final String imagePath;
  final String username;

  const DirectChat({
    Key? key,
    required this.reciveEmail,
    required this.senderEmail,
    required this.imagePath,
    required this.username,
  }) : super(key: key);

  @override
  State<DirectChat> createState() => _DirectChatState();
}

class _DirectChatState extends State<DirectChat> {
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
      // เช็คว่าผู้ใช้เลื่อนถึงตำแหน่งล่างสุดหรือไม่
      isAtBottom = scrollController.position.pixels ==
          scrollController.position.maxScrollExtent;
    } else {
      isAtBottom = false;
    }
  }

  Future<void> fetchMessages() async {
    final response = await http.get(
      Uri.parse(
        '${MyIp().domain}:3000/getdirectmessages?receive_email=${widget.reciveEmail}&sender_email=${widget.senderEmail}',
      ),
    );
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          messages = json.decode(response.body);
        });

        // เลื่อนเฉพาะเมื่อผู้ใช้อยู่ที่ตำแหน่งล่างสุด
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
      Uri.parse('${MyIp().domain}:3000/sendmessagedirect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiver_email': widget.reciveEmail,
        'sender_email': widget.senderEmail,
        'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
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
      print('Failed to send message: ${response.body}');
      throw Exception('Failed to send message');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await http.post(
      Uri.parse('${MyIp().domain}:3000/deletemessagesdirect'),
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
      Uri.parse('${MyIp().domain}:3000/sendimagedirect'),
    );
    request.fields['receiver_email'] = widget.reciveEmail;
    request.fields['sender_email'] = widget.senderEmail!;

    for (var image in images) {
      request.files.add(
          await http.MultipartFile.fromPath('sendimagedirect', image.path));
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

  void viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
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
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink,
              backgroundImage: widget.imagePath.isNotEmpty
                  ? NetworkImage(
                      '${MyIp().domain}:3000/editimageprofile/${widget.imagePath}',
                    )
                  : null,
              child: widget.imagePath.isEmpty
                  ? Text(
                      widget.reciveEmail[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            SizedBox(width: 20),
            Text(
              widget.username,
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.image_sharp, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageHistoryDirect(
                    senderEmail: widget.senderEmail,
                    reciveEmail: widget.reciveEmail,
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
                    messages[index]['sender_email'] == widget.senderEmail;

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
                                backgroundColor: Colors.pink,
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
                                      if (widget.senderEmail ==
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
                                                  ['id_direct']
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
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8.0),
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
                                          : Text(messages[index]['messages']),
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

class ImageHistoryDirect extends StatefulWidget {
  final String? senderEmail;
  final String reciveEmail;

  ImageHistoryDirect({required this.senderEmail, required this.reciveEmail});

  @override
  _ImageHistoryDirectState createState() => _ImageHistoryDirectState();
}

class _ImageHistoryDirectState extends State<ImageHistoryDirect> {
  List<Map<String, dynamic>> images = [];

  @override
  void initState() {
    super.initState();
    getImagesHistory();
  }

  Future<void> getImagesHistory() async {
    try {
      final response = await http.post(
        Uri.parse('${MyIp().domain}:3000/historyimagedirect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_email': widget.senderEmail,
          'receiver_email': widget.reciveEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if data['images'] contains valid data
        if (data['images'] == null || data['images'].isEmpty) {
          setState(() {
            images = [];
          });
          return;
        }

        setState(() {
          images = List<Map<String, dynamic>>.from(data['images']);
          print('Images: $images');
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to load images: ${errorData["message"]}');
      }
    } catch (error) {
      print("Error: $error");
      // Optional: Display an error message to the user in the UI
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
                      children: images[index]['imageurl'] != null &&
                              images[index]['imageurl'] is List
                          ? (images[index]['imageurl'] as List)
                              .map<Widget>((imageUrl) {
                              String fullImageUrl =
                                  '${MyIp().domain}:3000/sendimagedirect/$imageUrl';
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullScreenImage(
                                            imageUrl: fullImageUrl),
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey,
                                              child: Icon(Icons.error,
                                                  color: Colors.red),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList()
                          : [], // Fallback for when imageurl is null or not a list
                    ),
                  ],
                );
              },
            ),
    );
  }
}
