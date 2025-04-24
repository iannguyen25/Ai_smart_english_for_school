import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/discussion.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'discussion_detail_screen.dart';

class ForumTab extends StatefulWidget {
  final String classroomId;
  final bool isMember;
  final bool isTeacher;
  
  const ForumTab({
    Key? key,
    required this.classroomId,
    required this.isMember,
    required this.isTeacher,
  }) : super(key: key);
  
  @override
  _ForumTabState createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  final _auth = auth.FirebaseAuth.instance;
  
  List<Discussion> _discussions = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }
  
  // Tải dữ liệu diễn đàn
  Future<void> _loadDiscussions() async {
    try {
      setState(() => _isLoading = true);
      
      // Giả lập tải dữ liệu diễn đàn
      await Future.delayed(Duration(seconds: 1));
      
      final discussions = [
        Discussion(
          id: '1',
          userId: 'user1',
          content: 'Thắc mắc về bài tập tuần 1?',
          type: DiscussionType.question,
          isPinned: true,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2))),
        ),
        Discussion(
          id: '2',
          userId: 'user2',
          content: 'Mọi người chia sẻ tài liệu tham khảo được không?',
          type: DiscussionType.question,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
        ),
        Discussion(
          id: '3',
          userId: 'user3',
          content: 'Thông báo: Lịch học tuần sau sẽ thay đổi',
          type: DiscussionType.comment,
          isPinned: true,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5))),
        ),
      ];
      
      if (!mounted) return;

      setState(() {
        _discussions = discussions;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      print('Error loading discussions: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDiscussions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diễn đàn lớp học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trao đổi, hỏi đáp và thảo luận về nội dung bài học',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.isMember)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateDiscussionDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo chủ đề mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Discussions list
          Expanded(
            child: _discussions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.forum_outlined,
                    message: 'Chưa có chủ đề thảo luận nào',
                    description: widget.isMember
                        ? 'Hãy tạo chủ đề thảo luận đầu tiên'
                        : 'Tham gia lớp học để bắt đầu thảo luận',
                  )
                : ListView.builder(
                    itemCount: _discussions.length,
                    itemBuilder: (context, index) {
                      final discussion = _discussions[index];
                      return _buildDiscussionItem(discussion);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Hiển thị trạng thái rỗng
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  // Hiển thị một item thảo luận
  Widget _buildDiscussionItem(Discussion discussion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Mở màn hình chi tiết thảo luận
            Get.to(() => DiscussionDetailScreen(
              classroomId: widget.classroomId,
              discussion: discussion,
              isMember: widget.isMember,
              isTeacher: widget.isTeacher,
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Avatar placeholder
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(discussion.userId[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    // Author info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Người dùng ${discussion.userId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(discussion.createdAt?.toDate() ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pill showing the type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDiscussionTypeColor(discussion.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        discussion.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    discussion.content,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like button
                    InkWell(
                      onTap: () {
                        // Like action
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_up_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${discussion.likes.length}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Reply count
                    FutureBuilder<List<Discussion>>(
                      future: Discussion.getReplies(discussion.id!),
                      builder: (context, snapshot) {
                        final replyCount = snapshot.data?.length ?? 0;
                        return Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$replyCount',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Màu cho các loại thảo luận
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Hiển thị hộp thoại tạo chủ đề thảo luận
  void _showCreateDiscussionDialog() {
    final contentController = TextEditingController();
    DiscussionType selectedType = DiscussionType.question;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo chủ đề thảo luận'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loại thảo luận
              DropdownButtonFormField<DiscussionType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại thảo luận',
                ),
                items: DiscussionType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Nội dung
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Nhập nội dung thảo luận',
                ),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Lỗi',
                    'Vui lòng nhập nội dung thảo luận',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                // Thêm thảo luận mới vào danh sách
                final newDiscussion = Discussion(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: _auth.currentUser?.uid ?? 'unknown',
                  content: contentController.text.trim(),
                  type: selectedType,
                  createdAt: Timestamp.now(),
                );
                
                if (!mounted) return;
                
                setState(() {
                  _discussions.insert(0, newDiscussion);
                });
                
                Navigator.pop(context);
                Get.snackbar(
                  'Thành công',
                  'Đã tạo chủ đề thảo luận mới',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}
