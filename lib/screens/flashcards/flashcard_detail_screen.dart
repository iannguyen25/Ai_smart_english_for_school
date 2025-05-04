import 'package:base_flutter_framework/screens/flashcards/flashcard_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/auth_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/analytics_service.dart';
import 'create_edit_flashcard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardDetailScreen extends StatefulWidget {
  final String flashcardId;

  const FlashcardDetailScreen({Key? key, required this.flashcardId}) : super(key: key);

  @override
  _FlashcardDetailScreenState createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  final AuthService _authService = AuthService();
  final FlashcardService _flashcardService = FlashcardService();
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  String? _errorMessage;
  Flashcard? _flashcard;
  List<FlashcardItem> _items = [];
  bool _isOwner = false;
  bool _isTeacher = false;
  bool _hasEditPermission = false;
  int _viewedCards = 0;
  bool _isTracking = false;
  
  // Thêm ScrollController và biến để theo dõi trạng thái cuộn
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  Color _appBarColor = Colors.green.shade700;
  Color _appBarColorCollapsed = Colors.green.shade900;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo ScrollController và lắng nghe sự kiện cuộn
    _scrollController = ScrollController()
      ..addListener(_onScroll);
      
    _loadFlashcardData();
  }
  
  // Log hoạt động flashcard
  void _logFlashcardActivity({required String action}) {
    if (_flashcard == null || _authService.currentUser == null) return;
    
    // Chỉ log khi có lessonId và classroomId
    if (_flashcard!.lessonId == null || _flashcard!.classroomId == null) return;
    
    _analyticsService.trackFlashcardActivity(
      userId: _authService.currentUser!.id ?? '',
      lessonId: _flashcard!.lessonId ?? '',
      classroomId: _flashcard!.classroomId ?? '',
      flashcardId: widget.flashcardId,
      flashcardTitle: _flashcard!.title ?? 'Untitled Flashcard',
      action: action,
      totalCards: _items.length,
      viewedCards: _viewedCards,
      timestamp: DateTime.now(),
    );
  }
  
  // Phương thức này được gọi khi xem một flashcard
  void _trackCardView() {
    if (!_isTracking) {
      // Bắt đầu tracking nếu chưa bắt đầu
      _isTracking = true;
      _logFlashcardActivity(action: 'start_viewing');
    }
    
    setState(() {
      // Tăng số thẻ đã xem, nhưng không vượt quá tổng số thẻ
      if (_viewedCards < _items.length) {
        _viewedCards++;
      }
      
      // Log mỗi khi người dùng đạt các mốc xem thẻ
      if (_viewedCards == _items.length || 
          _viewedCards == (_items.length / 2).ceil() ||
          _viewedCards == (_items.length * 0.8).ceil()) {
        _logFlashcardActivity(action: 'progress_update');
      }
      
      // Nếu người dùng đã xem 80% thẻ, đánh dấu hoàn thành
      if (_viewedCards >= (_items.length * 0.8).ceil()) {
        _logFlashcardActivity(action: 'completed');
      }
    });
  }
  
  void _onScroll() {
    // Tính toán tỷ lệ cuộn (từ 0.0 đến 1.0)
    final double offset = _scrollController.offset;
    final double maxExtent = 180.0; // Chiều cao tối đa của SliverAppBar
    
    // Giới hạn tỷ lệ từ 0.0 đến 1.0
    final double scrollRatio = (offset / maxExtent).clamp(0.0, 1.0);
    final bool isScrolled = scrollRatio > 0.1;
    
    if (mounted && (_scrollOffset != scrollRatio || _isScrolled != isScrolled)) {
      setState(() {
        _scrollOffset = scrollRatio;
        _isScrolled = isScrolled;
        
        // Tính toán màu gradient dựa trên tỷ lệ cuộn
        _appBarColor = Color.lerp(
          Colors.green.shade700,
          _appBarColorCollapsed,
          scrollRatio
        )!;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    // Ghi lại quá trình xem flashcard khi rời khỏi màn hình
    _logFlashcardActivity(action: 'stop_viewing');
    
    super.dispose();
  }

  Future<void> _loadFlashcardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tải thông tin bộ thẻ
      final flashcard = await _flashcardService.getFlashcardById(widget.flashcardId);

      if (flashcard == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy bộ thẻ';
          _isLoading = false;
        });
        return;
      }

      // Kiểm tra quyền sở hữu
      final currentUser = _authService.currentUser;
      final isOwner = currentUser != null && currentUser.id == flashcard.userId;
      
      // Kiểm tra nếu là giáo viên
      bool isTeacher = false;
      bool hasEditPermission = isOwner;
      
      if (currentUser != null) {
        // Nếu có classroomId, kiểm tra xem người dùng có phải là giáo viên của lớp không
        if (flashcard.classroomId != null) {
          try {
            final classroom = await FirebaseFirestore.instance
                .collection('classrooms')
                .doc(flashcard.classroomId)
                .get();
                
            if (classroom.exists) {
              final teacherId = classroom.data()?['teacherId'];
              isTeacher = teacherId == currentUser.id;
              hasEditPermission = isOwner || isTeacher;
            }
          } catch (e) {
            print('Error checking teacher status: $e');
          }
        }
        
        // Nếu có lessonId, kiểm tra xem người dùng có phải là giáo viên tạo bài học không
        if (!isTeacher && flashcard.lessonId != null) {
          try {
            final lesson = await FirebaseFirestore.instance
                .collection('lessons')
                .doc(flashcard.lessonId)
                .get();
                
            if (lesson.exists) {
              final teacherId = lesson.data()?['teacherId'];
              isTeacher = teacherId == currentUser.id;
              hasEditPermission = isOwner || isTeacher;
            }
          } catch (e) {
            print('Error checking lesson teacher status: $e');
          }
        }
      }

      // Tải các thẻ
      final items = await _flashcardService.getFlashcardItems(widget.flashcardId);

      setState(() {
        _flashcard = flashcard;
        _items = items;
        _isOwner = isOwner;
        _isTeacher = isTeacher;
        _hasEditPermission = hasEditPermission;
        _isLoading = false;
      });
      
      // Log bắt đầu xem flashcard
      if (!isOwner && !isTeacher) {
        _logFlashcardActivity(action: 'start_viewing');
        _isTracking = true;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _flashcard == null
                  ? const Center(child: Text('Không tìm thấy bộ thẻ'))
                  : NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            expandedHeight: 180.0,
                            floating: false,
                            pinned: true,
                            elevation: _isScrolled ? 4 : 0,
                            backgroundColor: _appBarColor,
                            flexibleSpace: FlexibleSpaceBar(
                              title: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 - _scrollOffset * 2, // Giảm kích thước font khi cuộn
                                ),
                                child: Text(_flashcard!.title),
                              ),
                              titlePadding: EdgeInsets.lerp(
                                const EdgeInsets.only(left: 16, bottom: 16),
                                const EdgeInsets.only(left: 56, bottom: 16),
                                _scrollOffset
                              ),
                              collapseMode: CollapseMode.pin,
                              background: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _appBarColor,
                                      Color.lerp(Colors.green.shade500, _appBarColorCollapsed, _scrollOffset)!,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -50,
                                      top: -20,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 200 * (1 - _scrollOffset * 0.5),
                                        height: 200 * (1 - _scrollOffset * 0.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: -30,
                                      bottom: -50,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 180 * (1 - _scrollOffset * 0.5),
                                        height: 180 * (1 - _scrollOffset * 0.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 70 * (1 - _scrollOffset),
                                      left: 0,
                                      right: 0,
                                      child: AnimatedOpacity(
                                        opacity: 1 - _scrollOffset,
                                        duration: const Duration(milliseconds: 200),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _flashcard!.description,
                                                style: TextStyle(
                                                  color:
                                                      Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    _flashcard!.isPublic
                                                        ? Icons.public
                                                        : Icons.lock,
                                                    color: Colors.white70,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _flashcard!.isPublic
                                                        ? 'Công khai'
                                                        : 'Riêng tư',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              if (_hasEditPermission && _flashcard != null)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () async {
                                    final result = await Get.to(() =>
                                        CreateEditFlashcardScreen(
                                            flashcard: _flashcard));
                                    if (result == true) {
                                      _loadFlashcardData();
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onPressed: _flashcard == null ? null : () => _showOptions(),
                              ),
                            ],
                          ),
                        ];
                      },
                      body: _buildFlashcardContent(),
                    ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Get.to(() => FlashcardPracticeScreen(
                      flashcard: _flashcard!,
                      items: _items,
                    ));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Luyện tập'),
              backgroundColor: Colors.green.shade700,
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFlashcardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin bộ thẻ
          Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: _getUserName(_flashcard!.userId),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                          Text(
                            'Tác giả',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(_flashcard!.createdAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Ngày tạo',
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
          const SizedBox(height: 24),

          // Danh sách thẻ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.style,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thẻ (${_items.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_hasEditPermission)
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Get.to(() =>
                        CreateEditFlashcardScreen(flashcard: _flashcard));
                    if (result == true) {
                      _loadFlashcardData();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_items.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildFlashcardItem(item, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có thẻ nào trong bộ này',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm thẻ để bắt đầu học',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (_hasEditPermission)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.to(() =>
                      CreateEditFlashcardScreen(flashcard: _flashcard));
                  if (result == true) {
                    _loadFlashcardData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm thẻ mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardItem(FlashcardItem item, int index) {
    // Tạo màu dựa trên index
    final colorIndex = index % 5;
    final cardColors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.purple.shade50,
      Colors.orange.shade50,
      Colors.teal.shade50,
    ];
    final iconColors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
    ];

    return GestureDetector(
      onTap: () => _showFlashcardItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColors[colorIndex],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: iconColors[colorIndex],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thẻ ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColors[colorIndex],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.type == FlashcardItemType.imageToText && item.questionImage != null && item.questionImage!.isNotEmpty) ...[
                    // Hiển thị ảnh và chú thích cho kiểu imageToText
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.questionImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (item.questionCaption != null && item.questionCaption!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Chú thích:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.questionCaption!,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Định nghĩa:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.answer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                  else if (item.type == FlashcardItemType.imageToImage) ...[
                    // Hiển thị cả 2 ảnh cho kiểu imageToImage
                    if (item.questionImage != null && item.questionImage!.isNotEmpty) ...[
                      Text(
                        'Ảnh từ vựng',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.questionImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (item.questionCaption != null && item.questionCaption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Chú thích:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.questionCaption!,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    if (item.answerImage != null && item.answerImage!.isNotEmpty) ...[
                      Text(
                        'Ảnh minh họa',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.answerImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (item.answerCaption != null && item.answerCaption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Chú thích:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.answerCaption!,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ]
                  else ...[
                    // Hiển thị các kiểu khác như cũ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Từ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.question,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.translate,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Định nghĩa',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.answer,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashcardItemDetail(FlashcardItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Câu hỏi:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.question,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Câu trả lời:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.answer,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (item.answerImage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Hình ảnh:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      item.answerImage!,
                      fit: BoxFit.cover,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_hasEditPermission)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteFlashcardItem(item);
                          },
                          icon: const Icon(Icons.delete),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFlashcardItem(FlashcardItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa thẻ'),
          content: const Text('Bạn có chắc chắn muốn xóa thẻ này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _flashcardService.deleteFlashcardItem(item.id!);

      // Tải lại dữ liệu
      _loadFlashcardData();

      Get.snackbar(
        'Thành công',
        'Đã xóa thẻ',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'Lỗi',
        'Không thể xóa thẻ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showOptions() {
    if (_flashcard == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasEditPermission) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => CreateEditFlashcardScreen(
                      flashcard: _flashcard,
                    ));
                    if (result == true) {
                      _loadFlashcardData();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(_flashcard!.isPublic ? Icons.lock : Icons.public),
                  title: Text(_flashcard!.isPublic ? 'Đặt riêng tư' : 'Đặt công khai'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _flashcardService.toggleFlashcardVisibility(_flashcard!.id!);
                      _loadFlashcardData();
                      Get.snackbar(
                        'Thành công',
                        'Đã thay đổi trạng thái công khai',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Lỗi',
                        e.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
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
                    
                    if (confirm == true) {
                      try {
                        await _flashcardService.deleteFlashcard(_flashcard!.id!);
                        Get.back(result: true);
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
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                  Get.snackbar(
                    'Thông báo',
                    'Tính năng đang được phát triển',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final user = await _authService.getUserByIdCached(userId);
      if (user != null) {
        return '${user.firstName} ${user.lastName}'.trim();
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'Người dùng';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}