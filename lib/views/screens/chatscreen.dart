import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('chats');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? receiverName;
  bool _isLoadingMessages = true;
  bool _isSendingImage = false;
  bool _hasMessages = false;
  bool _isSendingMessage = false;

  // Cache for messages to prevent unnecessary rebuilds
  List<MapEntry> _messageCache = [];
  Map<String, List<MapEntry>> _groupedMessageCache = {};

  Future<void> imagepicker() async {
    final result = await _picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        _image = result;
      });
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final String fileName = 'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> fetchReceiverName() async {
    final userSnapshot = await FirebaseDatabase.instance.ref('users/${widget.receiverId}').get();
    if (userSnapshot.exists) {
      final data = userSnapshot.value as Map<dynamic, dynamic>;
      final role = data['role'] ?? 'customer';

      setState(() {
        if (role == 'Vendor') {
          receiverName = data['businessName'] ?? 'Vendor';
        } else {
          receiverName = data['fullName'] ?? 'Customer';
        }
      });
    } else {
      setState(() {
        receiverName = 'User';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchReceiverName();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final event = await _messagesRef.child(widget.chatId).once();
      final data = event.snapshot.value;

      setState(() {
        _hasMessages = data != null && (data as Map).isNotEmpty;
        _isLoadingMessages = false;
      });

      // Scroll to bottom after initial load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error loading initial messages: $e');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Map<String, List<MapEntry>> _groupMessagesByDate(Map<dynamic, dynamic> messages) {
    Map<String, List<MapEntry>> groupedMessages = {};
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    List<MapEntry> sortedMessages = messages.entries.toList()
      ..sort((a, b) {
        var aTime = a.value['timestamp'] ?? 0;
        var bTime = b.value['timestamp'] ?? 0;
        return aTime.compareTo(bTime);
      });

    for (var message in sortedMessages) {
      DateTime? timestamp;
      try {
        if (message.value['timestamp'] is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(message.value['timestamp']);
        }
      } catch (_) {}

      String dateKey = "Other";
      if (timestamp != null) {
        DateTime messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
        if (messageDate == today) {
          dateKey = "Today";
        } else if (messageDate == yesterday) {
          dateKey = "Yesterday";
        } else {
          dateKey = DateFormat('MMMM d, y').format(timestamp);
        }
      }

      if (!groupedMessages.containsKey(dateKey)) {
        groupedMessages[dateKey] = [];
      }
      groupedMessages[dateKey]!.add(message);
    }

    return groupedMessages;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            maxWidth: 40,
            maxHeight: 40,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Text(
                  receiverName != null && receiverName!.isNotEmpty
                      ? receiverName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Color(0xFFFF4A49),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                receiverName != null ? receiverName! : 'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: Color(0xFFFF4A49),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<DatabaseEvent>(
              stream: _messagesRef
                  .child(widget.chatId)
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!_hasMessages) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && _messageCache.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.snapshot.value;
                if (data == null || (data as Map).isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Process messages
                Map<dynamic, dynamic> messages = data;
                final groupedMessages = _groupMessagesByDate(messages);

                // Update cache only if messages have changed
                if (_groupedMessageCache.toString() != groupedMessages.toString()) {
                  _groupedMessageCache = groupedMessages;
                  _messageCache = groupedMessages.entries
                      .expand((entry) => entry.value)
                      .toList();
                }

                // Scroll to bottom when new messages arrive
                if (_messageCache.isNotEmpty && _scrollController.hasClients) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: EdgeInsets.only(bottom: 8),
                  itemCount: _groupedMessageCache.entries.fold<int>(0, (sum, entry) => sum + entry.value.length + 1),
                  itemBuilder: (context, index) {
                    int currentIndex = 0;
                    for (var entry in _groupedMessageCache.entries) {
                      if (index == currentIndex) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      currentIndex++;

                      if (index < currentIndex + entry.value.length) {
                        var message = entry.value[index - currentIndex].value;
                        return _buildMessageItem(message);
                      }
                      currentIndex += entry.value.length;
                    }
                    return SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<dynamic, dynamic> message) {
    bool isMe = message['senderId'] == _currentUser?.uid;
    DateTime? timestamp;
    try {
      if (message['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
      }
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message['imageUrl'] != null)
              _buildImageMessage(message, timestamp, isMe),
            if (message['text'] != null && message['text'].isNotEmpty)
              _buildTextMessage(message, timestamp, isMe),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(Map<dynamic, dynamic> message, DateTime? timestamp, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isMe ? Color(0xFFFFD6D6) : Colors.grey[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Image.network(
              message['imageUrl'],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: 200,
                  color: isMe ? Color(0xFFFFD6D6) : Colors.grey[50],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: 200,
                  color: isMe ? Color(0xFFFFD6D6) : Colors.grey[50],
                  child: Icon(Icons.error),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 4, right: 8, bottom: 6),
          child: Text(
            timestamp != null
                ? DateFormat('hh:mm a').format(timestamp)
                : '',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextMessage(Map<dynamic, dynamic> message, DateTime? timestamp, bool isMe) {
    final text = message['text'] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: isMe ? Color(0xFFFFD6D6) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              timestamp != null
                  ? DateFormat('hh:mm a').format(timestamp)
                  : '',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white, // Dark: Dark grey, Light: White
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_image != null)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_image!.path),
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _image = null;
                        });
                      },
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: isDarkMode ? Colors.grey[600] : Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87, // Text color
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: isDarkMode ? Color(0xFF2D2D2D) : Colors.grey[50], // Dark: Darker grey, Light: Light grey
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500], // Hint color
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: imagepicker,
                          icon: Icon(Icons.image,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600], // Icon color
                          ),
                        ),
                      ],
                    ),
                  ),
                  cursorColor: Color(0xFFFF4A49), // Keep your brand color for cursor
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFF4A49), // Keep your brand color for send button
                  shape: BoxShape.circle,
                ),
                child: _isSendingImage || _isSendingMessage
                    ? Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty && _image == null) return;

    setState(() {
      _isSendingImage = _image != null;
      _isSendingMessage = true;
    });

    try {
      if (_image != null) {
        String? imageUrl = await _uploadImage(_image!);
        if (imageUrl != null) {
          await _sendMessageToFirebase(text, imageUrl: imageUrl);
        }
      } else {
        await _sendMessageToFirebase(text);
      }

      _messageController.clear();
      setState(() {
        _image = null;
        _hasMessages = true;
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      setState(() {
        _isSendingImage = false;
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _sendMessageToFirebase(String text, {String? imageUrl}) async {
    Map<String, dynamic> message = {
      'text': text,
      'senderId': _currentUser?.uid,
      'receiverId': widget.receiverId,
      'timestamp': ServerValue.timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    await _messagesRef.child(widget.chatId).push().set(message);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}