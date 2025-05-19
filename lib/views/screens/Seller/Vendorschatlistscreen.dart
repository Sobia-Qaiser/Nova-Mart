import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../chatscreen.dart';

class VendorChatListScreen extends StatefulWidget {
  final String vendorId;

  VendorChatListScreen({required this.vendorId});

  @override
  _VendorChatListScreenState createState() => _VendorChatListScreenState();
}

class _VendorChatListScreenState extends State<VendorChatListScreen> {
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('chats');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> chatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _messagesRef.onChildChanged.listen((_) => _loadChats());
  }



  Future<void> markMessagesAsSeen(String chatId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('chats/$chatId');
      final event = await ref.once();
      final messages = event.snapshot.value as Map<dynamic, dynamic>?;

      if (messages != null) {
        await Future.wait(messages.entries.map((entry) async {
          final key = entry.key;
          final msg = Map<String, dynamic>.from(entry.value);

          // Check if the message is for the current vendor and not seen yet
          if (msg['receiverId'] == widget.vendorId && (msg['isSeen'] ?? false) == false) {
            await ref.child(key).update({'isSeen': true});
          }
        }));
      }
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  int getTotalUnreadCount() {
    return chatList.fold(
        0, (sum, chat) => sum + ((chat['unreadCount'] ?? 0) as int));
  } // add



  Future<String> _getCustomerName(String customerId) async {
    if (customerId.isEmpty) return 'Unknown Customer';
    try {
      final snapshot = await _usersRef.child(customerId).child('fullName').get();
      return snapshot.exists ? snapshot.value.toString() : 'Unknown Customer';
    } catch (e) {
      return 'Unknown Customer';
    }
  }

  Future<void> _loadChats() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseDatabase.instance.ref('chats').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> tempChatList = [];

        for (var entry in data.entries) {
          final chatId = entry.key;
          final messagesData = entry.value as Map<dynamic, dynamic>?;

          if (messagesData != null && messagesData.isNotEmpty) {
            final messagesList = messagesData.entries.toList();

            var firstMsg = Map<String, dynamic>.from(messagesList.first.value);
            String senderId = firstMsg['senderId'];
            String receiverId = firstMsg['receiverId'];

            if (senderId != widget.vendorId && receiverId != widget.vendorId) continue;

            String customerId = (senderId == widget.vendorId) ? receiverId : senderId;
            if (customerId == widget.vendorId) continue;

            int unreadCount = 0;
            for (var msg in messagesList) {
              final message = Map<String, dynamic>.from(msg.value);
              if (message['receiverId'] == widget.vendorId && (message['isSeen'] ?? false) == false) {
                unreadCount++;
              }
            }

            messagesList.sort((a, b) {
              final aTime = int.tryParse(a.value['timestamp'].toString()) ?? 0;
              final bTime = int.tryParse(b.value['timestamp'].toString()) ?? 0;
              return bTime.compareTo(aTime);
            });

            final lastMsg = Map<String, dynamic>.from(messagesList.first.value);
            final text = lastMsg['text']?.toString() ?? '';
            final image = lastMsg['imageBase64']?.toString();
            final lastMessage = text.isNotEmpty ? text : (image != null && image.isNotEmpty) ? 'Photo' : '...';
            final lastMessageTime = int.tryParse(lastMsg['timestamp'].toString()) ?? 0;

            tempChatList.add({
              'chatId': chatId,
              'customerId': customerId,
              'customerName': 'Loading...', // Step 1: Show placeholder
              'lastMessage': lastMessage,
              'lastMessageTime': lastMessageTime,
              'unreadCount': unreadCount,
            });
          }
        }

        // Step 2: Sort by time before showing initial list
        tempChatList.sort((a, b) => b['lastMessageTime'].compareTo(a['lastMessageTime']));

        // Show initial chat list with placeholders
        setState(() {
          chatList = List.from(tempChatList);
        });

        // Step 3: Load names progressively
        for (int i = 0; i < tempChatList.length; i++) {
          final customerName = await _getCustomerName(tempChatList[i]['customerId']);
          tempChatList[i]['customerName'] = customerName;

          if (i % 5 == 0) {
            setState(() {
              chatList = List.from(tempChatList);
            });
          }
        }

        // Final state update
        setState(() {
          chatList = tempChatList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      setState(() => _isLoading = false);
    }
  }


  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final isToday = dt.day == now.day && dt.month == now.month && dt.year == now.year;

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
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context, getTotalUnreadCount()),
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
            Text('No customer chats available',
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
              return Material(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                elevation: 0.5,
                child: InkWell(
                  onTap: () {

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                          chatId: chat['chatId'],
                          senderId: widget.vendorId,
                          receiverId: chat['customerId'],
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    ).then((_) => _loadChats());

                    markMessagesAsSeen(chat['chatId']);
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEC7070),
                          ),
                          child: Center(
                            child: Text(
                              chat['customerName'][0].toUpperCase(),
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
                                      chat['customerName'],
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
                                      color: (chat['unreadCount'] ?? 0) > 0
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
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
                                          size: 14,
                                          color: Colors.grey[500]),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(8),
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
            },
          ),
        ),
      ),
    );
  }
}