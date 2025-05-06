import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/discussion.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import 'dart:developer' as dev;
import 'dart:async';

class DiscussionDetailScreen extends StatefulWidget {
  final String classroomId;
  final Discussion discussion;
  final bool isMember;
  final bool isTeacher;

  const DiscussionDetailScreen({
    Key? key,
    required this.classroomId,
    required this.discussion,
    required this.isMember,
    required this.isTeacher,
  }) : super(key: key);

  @override
  _DiscussionDetailScreenState createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final _auth = auth.FirebaseAuth.instance;
  final _userService = UserService();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;

  List<Discussion> _replies = [];
  Map<String, User> _users = {};
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription? _repliesSubscription;

  @override
  void initState() {
    super.initState();
    // Enable debug prints
    debugPrint = (String? message, {int? wrapWidth}) {
      dev.log(message ?? '', name: 'DiscussionDetail');
    };
    _setupRepliesStream();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _repliesSubscription?.cancel();
    super.dispose();
  }

  void _setupRepliesStream() {
    debugPrint('🔄 Setting up replies stream...');
    debugPrint('📝 Discussion ID: ${widget.discussion.id}');
    
    _repliesSubscription = _firestore
        .collection('discussions')
        .where('parentId', isEqualTo: widget.discussion.id)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) async {
      debugPrint('📥 Received ${snapshot.docChanges.length} changes');
      
      for (var change in snapshot.docChanges) {
        debugPrint('📝 Change type: ${change.type} for doc: ${change.doc.id}');
        
        switch (change.type) {
          case DocumentChangeType.added:
            final reply = Discussion.fromMap(change.doc.data()!, change.doc.id);
            if (!_replies.any((r) => r.id == reply.id)) {
              setState(() {
                _replies.add(reply);
                _replies.sort((a, b) => 
                  (a.createdAt ?? Timestamp.now())
                    .compareTo(b.createdAt ?? Timestamp.now()));
              });
              debugPrint('✅ Added new reply: ${reply.id}');
            }
            break;
            
          case DocumentChangeType.modified:
            final reply = Discussion.fromMap(change.doc.data()!, change.doc.id);
            setState(() {
              final index = _replies.indexWhere((r) => r.id == reply.id);
              if (index != -1) {
                _replies[index] = reply;
                debugPrint('✅ Updated reply: ${reply.id}');
              }
            });
            break;
            
          case DocumentChangeType.removed:
            setState(() {
              _replies.removeWhere((r) => r.id == change.doc.id);
              debugPrint('✅ Removed reply: ${change.doc.id}');
            });
            break;
        }
      }

      // Load user info for new replies
      final newUserIds = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) => change.doc.data()!['userId'] as String)
          .toSet();
      
      if (newUserIds.isNotEmpty) {
        debugPrint('🔄 Loading info for ${newUserIds.length} new users');
        final users = await Future.wait(
          newUserIds.map((uid) => _userService.getUserById(uid))
        );
        
        setState(() {
          _users.addAll(
            Map.fromEntries(
              users.where((u) => u != null).map((u) => MapEntry(u!.id!, u))
            )
          );
        });
        debugPrint('✅ Updated user info');
      }

      // Scroll to bottom after updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          debugPrint('✅ Scrolled to bottom');
        }
      });
    }, onError: (error) {
      debugPrint('❌ Error in replies stream: $error');
      Get.snackbar(
        'Lỗi',
        'Không thể tải tin nhắn: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    });

    setState(() => _isLoading = false);
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    debugPrint('🔄 Starting to send reply...');
    debugPrint('📝 Content: $content');
    setState(() => _isSending = true);

    try {
      // Tạo reply mới
      debugPrint('🔄 Creating new reply...');
      final newReply = await Discussion.create(
        userId: _auth.currentUser?.uid ?? '',
        content: content,
        type: DiscussionType.answer,
        parentId: widget.discussion.id,
        classroomId: widget.classroomId,
      );

      if (newReply != null) {
        debugPrint('✅ Reply created successfully');
        debugPrint('📝 New reply ID: ${newReply.id}');
        _replyController.clear();
        debugPrint('✅ Cleared reply input');
      } else {
        debugPrint('❌ Failed to create reply');
      }
    } catch (e) {
      debugPrint('❌ Error sending reply: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể gửi tin nhắn: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildUserRole(User user) {
    Color bgColor;
    Color textColor;
    String roleText;

    if (user.roleId == 'admin') {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
      roleText = 'Admin';
    } else if (widget.isTeacher || user.roleId == 'teacher') {
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
      roleText = 'Giáo viên';
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      roleText = 'Học viên';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        roleText,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Discussion message, bool isMainDiscussion) {
    final user = _users[message.userId];
    final isCurrentUser = message.userId == _auth.currentUser?.uid;
    final time = message.createdAt?.toDate() ?? DateTime.now();
    final formattedTime = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    final formattedDate = '${time.day}/${time.month}/${time.year}';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: isMainDiscussion ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (user.fullName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? 'Người dùng',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    _buildUserRole(user),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Container(
            margin: EdgeInsets.only(
              left: !isCurrentUser ? 40 : 0,
              right: isCurrentUser ? 0 : 40,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isCurrentUser 
                ? Colors.blue.shade100 
                : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMainDiscussion) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDiscussionTypeColor(message.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.type.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: isMainDiscussion ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: !isCurrentUser ? 40 : 0,
              right: isCurrentUser ? 0 : 40,
              top: 4,
            ),
            child: Text(
              '$formattedTime, $formattedDate',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDiscussionTypeColor(DiscussionType type) {
    switch (type) {
      case DiscussionType.question:
        return Colors.orange;
      case DiscussionType.answer:
        return Colors.green;
      case DiscussionType.comment:
        return Colors.blue;
      case DiscussionType.explanation:
        return Colors.purple;
      case DiscussionType.feedback:
        return Colors.teal;
      case DiscussionType.suggestion:
        return Colors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thảo luận'),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildMessageBubble(widget.discussion, true),
                      ..._replies.map((reply) => _buildMessageBubble(reply, false)),
                    ],
                  ),
          ),

          // Reply input
          if (widget.isMember)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _isSending ? null : _sendReply,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: _isSending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 