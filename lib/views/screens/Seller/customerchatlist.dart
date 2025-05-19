import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../chatscreen.dart';

class CustomerChatListScreen extends StatefulWidget {
  final String customerId;

  CustomerChatListScreen({required this.customerId});

  @override
  _CustomerChatListScreenState createState() => _CustomerChatListScreenState();
}

class _CustomerChatListScreenState extends State<CustomerChatListScreen> {
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('chats');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> chatList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Listen for real-time updates
    _messagesRef.onChildChanged.listen((_) => _loadChats());
    _messagesRef.onChildAdded.listen((_) => _loadChats());
  }

  Future<void> markMessagesAsSeen(String chatId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$chatId');
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      Map<String, dynamic> updatesToMake = {};

      snapshot.children.forEach((message) {
        final msg = message.value as Map;
        if (msg['receiverId'] == widget.customerId && msg['isSeen'] != true) {
          updatesToMake['${message.key}/isSeen'] = true;
        }
      });

      if (updatesToMake.isNotEmpty) {
        await ref.update(updatesToMake);
      }
    } catch (e) {
      debugPrint('Error in markMessagesAsSeen: $e');
    }
  }

  void _updateUnreadCount(String chatId, int count) {
    setState(() {
      final index = chatList.indexWhere((chat) => chat['chatId'] == chatId);
      if (index != -1) {
        chatList[index]['unreadCount'] = count;
      }
    });
  }

  int getTotalUnreadCount() {
    return chatList.fold(
        0, (sum, chat) => sum + ((chat['unreadCount'] ?? 0) as int));
  } // add

  Future<String> _getVendorName(String vendorId) async {
    if (vendorId.isEmpty) return 'Unknown Vendor';
    try {
      final snapshot = await _usersRef.child(vendorId)
          .child('businessName')
          .get();
      return snapshot.exists ? snapshot.value.toString() : 'Unknown Vendor';
    } catch (e) {
      return 'Unknown Vendor';
    }
  }

  Future<void> _loadChats() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('chats').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;
      List<Map<String, dynamic>> tempChatList = [];

      if (data != null) {
        for (var chatId in data.keys) {
          try {
            // Get last message
            final lastMsgSnapshot = await FirebaseDatabase.instance
                .ref('chats/$chatId')
                .orderByChild('timestamp')
                .limitToLast(1)
                .get();

            if (lastMsgSnapshot.exists) {
              final lastMsgEntry = lastMsgSnapshot.children.last;
              final lastMsg = Map<String, dynamic>.from(
                  lastMsgEntry.value as Map);

              // Check if customer is in this chat
              if (lastMsg['senderId'] != widget.customerId &&
                  lastMsg['receiverId'] != widget.customerId) {
                continue;
              }

              final vendorId = (lastMsg['senderId'] == widget.customerId)
                  ? lastMsg['receiverId']
                  : lastMsg['senderId'];

              if (vendorId == widget.customerId) continue;

              // Get unread count - more efficient query
              final unreadSnapshot = await FirebaseDatabase.instance
                  .ref('chats/$chatId')
                  .orderByChild('receiverId')
                  .equalTo(widget.customerId)
                  .get();

              int unreadCount = 0;
              unreadSnapshot.children.forEach((msg) {
                if ((msg
                    .child('isSeen')
                    .value ?? false) == false) {
                  unreadCount++;
                }
              });

              tempChatList.add({
                'chatId': chatId.toString(),
                'vendorId': vendorId.toString(),
                'vendorName': await _getVendorName(vendorId.toString()),
                'lastMessage': lastMsg['text']
                    ?.toString()
                    .isNotEmpty ?? false
                    ? lastMsg['text'].toString()
                    : (lastMsg['imageBase64']
                    ?.toString()
                    .isNotEmpty ?? false)
                    ? 'Photo'
                    : '...',
                'lastMessageTime': int.tryParse(
                    lastMsg['timestamp'].toString()) ?? 0,
                'unreadCount': unreadCount,
              });
            }
          } catch (e) {
            debugPrint('Error processing chat $chatId: $e');
          }
        }

        // Sort by time
        tempChatList.sort((a, b) =>
            b['lastMessageTime'].compareTo(a['lastMessageTime']));
      }

      setState(() => chatList = tempChatList);
    } catch (e) {
      debugPrint('Error loading chats: $e');
    }
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final isToday = dt.day == now.day && dt.month == now.month &&
        dt.year == now.year;

    if (isToday) {
      int hour = dt.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        hour = hour == 12 ? 12 : hour - 12;
      }
      if (hour == 0) hour = 12;

      return '${hour}:${dt.minute.toString().padLeft(2, '0')} $period';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString()
          .padLeft(2, '0')}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFFFF4A49),
        elevation: 0,
      ),
      body: _isLoading && chatList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chatList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No vendor chats available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.withOpacity(0.6),
                )),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadChats,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: chatList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = chatList[index];
              return _buildChatItem(chat);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      elevation: 0.5,
      child: InkWell(
        onTap: () async {
          // First mark messages as seen
          await markMessagesAsSeen(chat['chatId']);
          // Then navigate to chat screen
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ChatScreen(
                    chatId: chat['chatId'],
                    senderId: widget.customerId,
                    receiverId: chat['vendorId'],
                  ),
              transitionsBuilder: (context, animation, secondaryAnimation,
                  child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          // Return the updated unread count when popping
          Navigator.pop(context, getTotalUnreadCount());
          _loadChats();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Vendor Avatar
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEC7070),
                ),
                child: Center(
                  child: Text(
                    chat['vendorName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['vendorName'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: (chat['unreadCount'] ?? 0) > 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(chat['lastMessageTime']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (chat['lastMessage'] == 'Photo')
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.photo_camera_rounded,
                                size: 14, color: Colors.grey[500]),
                          ),
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: (chat['unreadCount'] ?? 0) > 0
                                  ? Colors.blueGrey[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        if ((chat['unreadCount'] ?? 0) > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6,
                                vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat['unreadCount'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}