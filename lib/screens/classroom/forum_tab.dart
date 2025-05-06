import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/discussion.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'discussion_detail_screen.dart';
import '../../services/discussion_service.dart';

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
  final _discussionService = DiscussionService();
  
  List<Discussion> _discussions = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _discussionSubscription;
  
  @override
  void initState() {
    super.initState();
    // Enable debug prints
    debugPrint = (String? message, {int? wrapWidth}) {
      dev.log(message ?? '', name: 'ForumTab');
    };
    _loadDiscussions();
    _subscribeToNotifications();
  }
  
  // Load discussions
  Future<void> _loadDiscussions() async {
    try {
      debugPrint('🔄 Starting to load discussions...');
      setState(() {
        _isLoading = true;
      });

      // Hủy subscription cũ nếu có
      if (_discussionSubscription != null) {
        debugPrint('🔄 Cancelling old subscription...');
        await _discussionSubscription?.cancel();
      }

      debugPrint('🔄 Creating new subscription...');
      // Tạo subscription mới
      _discussionSubscription = _discussionService
          .getClassroomDiscussionsStream(widget.classroomId)
          .listen(
        (discussions) {
          debugPrint('📥 Received ${discussions.length} discussions from stream');
          debugPrint('📝 First discussion: ${discussions.isNotEmpty ? discussions.first.content : "No discussions"}');
          
          if (mounted) {
      setState(() {
        _discussions = discussions;
        _isLoading = false;
        _errorMessage = null;
      });
            debugPrint('✅ Updated UI with new discussions');
          } else {
            debugPrint('⚠️ Widget not mounted, skipping UI update');
          }
        },
        onError: (error) {
          debugPrint('❌ Error in discussion stream: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.toString();
            });
            Get.snackbar(
              'Lỗi',
              'Không thể tải danh sách thảo luận',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      );
      debugPrint('✅ Successfully set up discussion stream');
    } catch (e) {
      debugPrint('❌ Error setting up discussion stream: $e');
      if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
        Get.snackbar(
          'Lỗi',
          'Không thể tải danh sách thảo luận',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
  
  // Xóa một chủ đề thảo luận
  Future<void> _deleteDiscussion(Discussion discussion) async {
    try {
      dev.log('Deleting discussion...', name: 'ForumTab');
      dev.log('Discussion ID: ${discussion.id}', name: 'ForumTab');
      
      await _discussionService.deleteDiscussion(discussion.id!);
      
      dev.log('Discussion deleted successfully', name: 'ForumTab');
      Get.snackbar(
        'Thành công',
        'Đã xóa chủ đề thảo luận',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      dev.log('Error deleting discussion: $e', name: 'ForumTab', error: e);
      Get.snackbar(
        'Lỗi',
        'Không thể xóa chủ đề thảo luận: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
                
                try {
                  await _createDiscussion(contentController.text.trim(), selectedType);
                } catch (e) {
                  dev.log('Error creating discussion: $e', name: 'ForumTab', error: e);
                  Get.snackbar(
                    'Lỗi',
                    'Không thể tạo chủ đề thảo luận: $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị hộp thoại chỉnh sửa chủ đề thảo luận
  void _showEditDiscussionDialog(Discussion discussion) {
    final contentController = TextEditingController(text: discussion.content);
    DiscussionType selectedType = discussion.type;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa chủ đề thảo luận'),
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
                
                try {
                  await _updateDiscussion(discussion, contentController.text.trim(), selectedType);
                } catch (e) {
                  dev.log('Error updating discussion: $e', name: 'ForumTab', error: e);
                  Get.snackbar(
                    'Lỗi',
                    'Không thể cập nhật chủ đề thảo luận: $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị menu tùy chọn cho một chủ đề thảo luận
  void _showDiscussionOptions(Discussion discussion) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isTeacher || discussion.userId == _auth.currentUser?.uid)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditDiscussionDialog(discussion);
              },
            ),
          if (widget.isTeacher || discussion.userId == _auth.currentUser?.uid)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc chắn muốn xóa chủ đề thảo luận này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteDiscussion(discussion);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (widget.isTeacher)
            ListTile(
              leading: Icon(
                discussion.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: discussion.isPinned ? Colors.blue : null,
              ),
              title: Text(discussion.isPinned ? 'Bỏ ghim' : 'Ghim lên đầu'),
              onTap: () async {
                try {
                  await _togglePinDiscussion(discussion);
                } catch (e) {
                  dev.log('Error toggling pin: $e', name: 'ForumTab', error: e);
                  Get.snackbar(
                    'Lỗi',
                    'Không thể thay đổi trạng thái ghim: $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
        ],
      ),
    );
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
                            'Người dùng ${discussion.userName}',
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
  
  Future<void> _subscribeToNotifications() async {
    try {
      await _discussionService.subscribeToClassroom(widget.classroomId);
    } catch (e) {
      dev.log('Error subscribing to notifications: $e', name: 'ForumTab', error: e);
    }
  }

  @override
  void dispose() {
    dev.log('Disposing ForumTab...', name: 'ForumTab');
    dev.log('Cancelling discussion subscription...', name: 'ForumTab');
    _discussionSubscription?.cancel();
    _discussionService.dispose();
    _unsubscribeFromNotifications();
    super.dispose();
    dev.log('ForumTab disposed', name: 'ForumTab');
  }

  Future<void> _unsubscribeFromNotifications() async {
    try {
      await _discussionService.unsubscribeFromClassroom(widget.classroomId);
    } catch (e) {
      dev.log('Error unsubscribing from notifications: $e', name: 'ForumTab', error: e);
    }
  }

  Future<void> _createDiscussion(String content, DiscussionType type) async {
    try {
      dev.log('Creating new discussion...', name: 'ForumTab');
      dev.log('Content: $content', name: 'ForumTab');
      dev.log('Type: $type', name: 'ForumTab');
      
      final newDiscussion = await _discussionService.createDiscussion(
        userId: _auth.currentUser?.uid ?? '',
        classroomId: widget.classroomId,
        content: content,
        type: type,
      );
      
      dev.log('Discussion created successfully', name: 'ForumTab');
      dev.log('New discussion ID: ${newDiscussion.id}', name: 'ForumTab');
      
                Get.snackbar(
                  'Thành công',
                  'Đã tạo chủ đề thảo luận mới',
                  snackPosition: SnackPosition.BOTTOM,
                );
    } catch (e) {
      dev.log('Error creating discussion: $e', name: 'ForumTab', error: e);
      Get.snackbar(
        'Lỗi',
        'Không thể tạo chủ đề thảo luận: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _updateDiscussion(Discussion discussion, String content, DiscussionType type) async {
    try {
      dev.log('Updating discussion...', name: 'ForumTab');
      dev.log('Discussion ID: ${discussion.id}', name: 'ForumTab');
      dev.log('New content: $content', name: 'ForumTab');
      dev.log('New type: $type', name: 'ForumTab');
      
      await _discussionService.updateDiscussion(
        discussion.id!,
        {
          'content': content,
          'type': type.toString(),
        },
      );
      
      dev.log('Discussion updated successfully', name: 'ForumTab');
      Get.snackbar(
        'Thành công',
        'Đã cập nhật chủ đề thảo luận',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      dev.log('Error updating discussion: $e', name: 'ForumTab', error: e);
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật chủ đề thảo luận: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _togglePinDiscussion(Discussion discussion) async {
    try {
      dev.log('Toggling pin status...', name: 'ForumTab');
      dev.log('Discussion ID: ${discussion.id}', name: 'ForumTab');
      dev.log('Current pin status: ${discussion.isPinned}', name: 'ForumTab');
      
      await _discussionService.togglePinDiscussion(
        discussion.id!,
        !discussion.isPinned,
      );
      
      dev.log('Pin status toggled successfully', name: 'ForumTab');
      Get.snackbar(
        'Thành công',
        discussion.isPinned ? 'Đã bỏ ghim chủ đề' : 'Đã ghim chủ đề lên đầu',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      dev.log('Error toggling pin: $e', name: 'ForumTab', error: e);
      Get.snackbar(
        'Lỗi',
        'Không thể thay đổi trạng thái ghim: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
