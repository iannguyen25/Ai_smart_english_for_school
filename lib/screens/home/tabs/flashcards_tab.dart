import 'package:base_flutter_framework/screens/flashcards/create_edit_flashcard_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/flashcard_detail_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/search_flashcards_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/flashcard_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/flashcard.dart';
import '../../../models/content_approval.dart';
import '../../../services/auth_service.dart';
import '../../../services/flashcard_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({Key? key}) : super(key: key);

  @override
  _FlashcardsTabState createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  final AuthService _authService = AuthService();
  final FlashcardService _flashcardService = FlashcardService();

  List<Flashcard> _userFlashcards = [];
  List<Flashcard> _publicFlashcards = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, bool> _isTeacherMap = {}; // Track teacher status for classrooms

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.id!;

      // Load user's flashcards
      final userCards = await _flashcardService.getUserFlashcards(userId);

      // Load public flashcards from other users
      final publicCards = await _flashcardService.getPublicFlashcards();
      final otherPublicCards =
          publicCards.where((card) => card.userId != userId).toList();

      setState(() {
        _userFlashcards = userCards;
        _publicFlashcards = otherPublicCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách bộ thẻ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa bộ thẻ'),
          content: const Text('Bạn có chắc chắn muốn xóa bộ thẻ này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _flashcardService.deleteFlashcard(flashcard.id!);
      _loadFlashcards();

      Get.snackbar(
        'Thành công',
        'Đã xóa bộ thẻ',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa bộ thẻ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Check if user is teacher for a flashcard
  Future<bool> _checkIsTeacher(Flashcard flashcard) async {
    // If the user is the owner, they already have full permissions
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;
    
    if (flashcard.userId == currentUser.id) return true;
    
    // Check if we already determined teacher status for this classroom/lesson
    final key = flashcard.classroomId ?? flashcard.lessonId;
    if (key != null && _isTeacherMap.containsKey(key)) {
      return _isTeacherMap[key] ?? false;
    }
    
    bool isTeacher = false;
    
    // Check if user is teacher of the classroom
    if (flashcard.classroomId != null) {
      try {
        final classroom = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(flashcard.classroomId)
            .get();
            
        if (classroom.exists) {
          final teacherId = classroom.data()?['teacherId'];
          isTeacher = teacherId == currentUser.id;
          
          // Cache the result
          _isTeacherMap[flashcard.classroomId!] = isTeacher;
        }
      } catch (e) {
        print('Error checking teacher status: $e');
      }
    }
    
    // Check if user is teacher of the lesson
    if (!isTeacher && flashcard.lessonId != null) {
      try {
        final lesson = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(flashcard.lessonId)
            .get();
            
        if (lesson.exists) {
          final teacherId = lesson.data()?['teacherId'];
          isTeacher = teacherId == currentUser.id;
          
          // Cache the result
          _isTeacherMap[flashcard.lessonId!] = isTeacher;
        }
      } catch (e) {
        print('Error checking lesson teacher status: $e');
      }
    }
    
    return isTeacher;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bộ thẻ'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Của tôi'),
              Tab(text: 'Công khai'),
            ],
            indicatorWeight: 3,
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Get.to(() => const SearchFlashcardsScreen()),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFlashcards,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      // Tab Của tôi
                      RefreshIndicator(
                        onRefresh: _loadFlashcards,
                        child: _userFlashcards.isEmpty
                            ? _buildEmptyState(true)
                            : _buildFlashcardGrid(_userFlashcards, true),
                      ),
                      // Tab Công khai
                      RefreshIndicator(
                        onRefresh: _loadFlashcards,
                        child: _publicFlashcards.isEmpty
                            ? _buildEmptyState(false)
                            : _buildFlashcardGrid(_publicFlashcards, false),
                      ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result =
                await Get.to(() => const CreateEditFlashcardScreen());
            if (result == true) {
              _loadFlashcards();
            }
          },
          child: const Icon(Icons.add),
          tooltip: 'Tạo bộ thẻ mới',
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isUserTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.style_outlined,
              size: 80,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUserTab ? 'Chưa có bộ thẻ nào' : 'Không có bộ thẻ công khai',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isUserTab
                ? 'Tạo bộ thẻ để học từ vựng hiệu quả'
                : 'Các bộ thẻ công khai sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isUserTab) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result =
                    await Get.to(() => const CreateEditFlashcardScreen());
                if (result == true) {
                  _loadFlashcards();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ thẻ mới'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardGrid(List<Flashcard> flashcards, bool isUserTab) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: flashcards.length,
        itemBuilder: (context, index) {
          final flashcard = flashcards[index];
          return _buildFlashcardCard(flashcard, isUserTab);
        },
      ),
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard, bool isUserTab) {
    final cardColors = [
      const Color(0xFFFFECB3), // Light Amber
      const Color(0xFFE1F5FE), // Light Blue
      const Color(0xFFE8F5E9), // Light Green
      const Color(0xFFF3E5F5), // Light Purple
      const Color(0xFFFFEBEE), // Light Red
      const Color(0xFFE0F2F1), // Light Teal
    ];

    // Sử dụng hash của ID flashcard để chọn màu cố định cho mỗi flashcard
    final colorIndex = flashcard.id.hashCode % cardColors.length;
    final cardColor = cardColors[colorIndex.abs()];

    return GestureDetector(
      onTap: () =>
          Get.to(() => FlashcardDetailScreen(flashcardId: flashcard.id!)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Flashcard header
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.style,
                  size: 40,
                  color: cardColor.withOpacity(0.8),
                ),
              ),
            ),
            // Flashcard info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flashcard.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUserTab)
                          GestureDetector(
                            onTap: () => _showFlashcardOptions(flashcard),
                            child: const Icon(
                              Icons.more_vert,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flashcard.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Show approval status for user's own flashcards
                    if (isUserTab && flashcard.approvalStatus != ApprovalStatus.approved) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(flashcard.approvalStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getStatusColor(flashcard.approvalStatus),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(flashcard.approvalStatus),
                              color: _getStatusColor(flashcard.approvalStatus),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              flashcard.approvalStatus.label,
                              style: TextStyle(
                                color: _getStatusColor(flashcard.approvalStatus),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          Icons.credit_card_outlined,
                          '${flashcard.items?.length}',
                        ),
                        Row(
                          children: [
                            Icon(
                              flashcard.isPublic
                                  ? Icons.public_outlined
                                  : Icons.lock_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              flashcard.isPublic ? 'Công khai' : 'Riêng tư',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashcardOptions(Flashcard flashcard) async {
    final bool isTeacher = await _checkIsTeacher(flashcard);
    final bool isOwner = _authService.currentUser?.id == flashcard.userId;
    final bool hasEditPermission = isOwner || isTeacher;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // For teachers or owners - edit functionality
            if (hasEditPermission)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa bộ thẻ'),
                onTap: () async {
                  Get.back();
                  final result = await Get.to(
                    () => CreateEditFlashcardScreen(flashcard: flashcard),
                  );
                  if (result == true) {
                    _loadFlashcards();
                  }
                },
              ),
            
            // View details for everyone
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Get.back();
                Get.to(() => FlashcardDetailScreen(flashcardId: flashcard.id!));
              },
            ),
            
            // Delete option only for owners
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Get.back();
                  _deleteFlashcard(flashcard);
                },
              ),
            
            // Practice for everyone
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Học ngay'),
              onTap: () async {
                Get.back();
                // Load the items first
                final items = await _flashcardService.getFlashcardItems(flashcard.id!);
                if (items.isNotEmpty) {
                  Get.to(() => FlashcardPracticeScreen(
                    flashcard: flashcard,
                    items: items,
                  ));
                } else {
                  Get.snackbar(
                    'Thông báo',
                    'Bộ thẻ này chưa có từ vựng nào',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.revising:
        return Colors.blue;
      case ApprovalStatus.reviewing:
        return Colors.amber;
      case ApprovalStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
  
  IconData _getStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Icons.pending;
      case ApprovalStatus.approved:
        return Icons.check_circle;
      case ApprovalStatus.rejected:
        return Icons.cancel;
      case ApprovalStatus.revising:
        return Icons.edit_note;
      case ApprovalStatus.reviewing:
        return Icons.search;
      case ApprovalStatus.cancelled:
        return Icons.block;
      default:
        return Icons.pending;
    }
  }
}
