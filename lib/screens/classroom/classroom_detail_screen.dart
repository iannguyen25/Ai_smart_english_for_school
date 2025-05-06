import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/classroom.dart';
import '../../models/lesson.dart';
import '../../services/classroom_service.dart';
import '../../services/lesson_service.dart';
import '../lessons/lesson_detail_screen.dart';
import 'create_edit_classroom_screen.dart';
import 'member_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import 'lesson_folder_screen.dart';
import 'classroom_reports_screen.dart';
import '../../models/discussion.dart';
import '../../models/learning_material.dart' as learning_material;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forum_tab.dart';
import 'materials_tab.dart';
import '../../services/auth_service.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailScreen({
    Key? key,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ClassroomDetailScreenState createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with TickerProviderStateMixin {
  final _classroomService = ClassroomService();
  final _userService = UserService();
  final _lessonService = LessonService();
  final _auth = auth.FirebaseAuth.instance;
  final _authService = AuthService();
  TabController? _tabController;
  Classroom? classroom;
  User? teacher;
  List<User> _members = [];
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  bool _isLoadingLessons = true;
  bool _isMember = false;
  bool _isTeacher = false;
  bool _isCourseClosed = false;
  String? _lessonErrorMessage;
  
  // Diễn đàn
  List<Discussion> _discussions = [];
  bool _isLoadingDiscussions = false;
  String? _discussionErrorMessage;
  
  // Tài liệu
  List<learning_material.LearningMaterial> _materials = [];
  bool _isLoadingMaterials = false;
  String? _materialErrorMessage;

  // Thêm ScrollController và biến để theo dõi trạng thái cuộn
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  Color _appBarColor = Colors.blue.shade200;
  Color _appBarColorCollapsed = Colors.blue.shade200;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Khởi tạo ScrollController và lắng nghe sự kiện cuộn
    _scrollController = ScrollController()..addListener(_onScroll);

    _loadClassroom();
    _loadLessons();
    _loadDiscussions();
    _loadMaterials();
    _checkCourseStatus();
  }

  void _onScroll() {
    // Tính toán tỷ lệ cuộn (từ 0.0 đến 1.0)
    final double offset = _scrollController.offset;
    final double maxExtent = 180.0; // Chiều cao tối đa của SliverAppBar

    // Giới hạn tỷ lệ từ 0.0 đến 1.0
    final double scrollRatio = (offset / maxExtent).clamp(0.0, 1.0);
    final bool isScrolled = scrollRatio > 0.1;

    if (mounted &&
        (_scrollOffset != scrollRatio || _isScrolled != isScrolled)) {
      setState(() {
        _scrollOffset = scrollRatio;
        _isScrolled = isScrolled;

        // Tính toán màu gradient dựa trên tỷ lệ cuộn
        _appBarColor = Color.lerp(Colors.blue.shade100.withOpacity(0),
            _appBarColorCollapsed, scrollRatio)!;
      });
    }
  }

  Future<void> _checkCourseStatus() async {
    print('DEBUG: Checking course status for classroom: ${widget.classroomId}');
    try {
      // First get the classroom to get courseId
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .get();
          
      if (classroomDoc.exists) {
        final classroomData = classroomDoc.data();
        final courseId = classroomData?['courseId'];
        print('DEBUG: Found classroom, courseId: $courseId');
        
        if (courseId != null) {
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();
          
          if (courseDoc.exists) {
            final courseData = courseDoc.data();
            print('DEBUG: Found course, isClosed: ${courseData?['isClosed']}');
            if (mounted) {
              setState(() {
                _isCourseClosed = courseData?['isClosed'] ?? false;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error checking course status: $e');
    }
  }

  Future<void> _loadClassroom() async {
    try {
      setState(() => _isLoading = true);
      final data = await _classroomService.getClassroom(widget.classroomId);
      
      if (data == null) {
        throw 'Không tìm thấy lớp học';
      }

      // Load thông tin giáo viên
      final teacherData = await _userService.getUserById(data.teacherId);

      // Kiểm tra xem có phải là giáo viên không
      final authUser = _auth.currentUser;
      final isTeacher = authUser != null && data.teacherId == authUser.uid;
 
      // Tính toán số lượng tab
      int tabCount = 2; // Bài học + Diễn đàn (cho tất cả người dùng)
      
      // Nếu là giáo viên, thêm tab Thành viên và Báo cáo
      if (isTeacher) {
        tabCount += 2; // Thêm Thành viên và Báo cáo
      }

      // Đảm bảo widget vẫn mounted trước khi setState
      if (!mounted) return;

      // Cập nhật state
      setState(() {
        classroom = data;
        teacher = teacherData;
        _isMember = data.memberIds.contains(authUser?.uid);
        _isTeacher = isTeacher;

        // Dispose controller cũ và gán controller mới
        _tabController?.dispose();
        _tabController = TabController(
          length: tabCount,
          vsync: this,
        );

        _isLoading = false;
      });

      // Sau khi load classroom xong, check course status
      await _checkCourseStatus();
    } catch (e) {
      // Đảm bảo widget vẫn mounted trước khi setState
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadLessons() async {
    try {
      setState(() => _isLoadingLessons = true);
      
      List<Lesson> lessons;
      // Đảm bảo luôn lấy từ biến class _isTeacher đã được set đúng trong _loadClassroom
      final bool isCurrentUserAdmin = _authService.isCurrentUserAdmin;
      print("DEBUG: _isTeacher = $_isTeacher, isAdmin = $isCurrentUserAdmin");
      
      if (_isTeacher || isCurrentUserAdmin) {
        // Giáo viên và admin nhìn thấy tất cả bài học
        lessons = await _lessonService.getLessonsByClassroom(widget.classroomId);
        print("DEBUG: Giáo viên/Admin đang tải bài học, số lượng: ${lessons.length}");
      } else {
        // Học viên chỉ nhìn thấy bài học đã được duyệt
        lessons = await _lessonService.getApprovedLessonsByClassroom(widget.classroomId);
        print("DEBUG: Học viên đang tải bài học đã duyệt, số lượng: ${lessons.length}");
      }
      
      if (!mounted) return;

      setState(() {
        _lessons = lessons;
        _isLoadingLessons = false;
        _lessonErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      print("DEBUG: Lỗi khi tải bài học: $e");
      setState(() {
        _isLoadingLessons = false;
        _lessonErrorMessage = e.toString();
      });
    }
  }

  Future<void> _loadDiscussions() async {
    try {
      setState(() => _isLoadingDiscussions = true);
      
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
        _isLoadingDiscussions = false;
        _discussionErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingDiscussions = false;
        _discussionErrorMessage = e.toString();
      });
      
      print('Error loading discussions: $e');
    }
  }
  
  // Tải dữ liệu tài liệu
  Future<void> _loadMaterials() async {
    try {
      setState(() => _isLoadingMaterials = true);
      
      // Giả lập tải dữ liệu tài liệu
      await Future.delayed(Duration(seconds: 1));
      
      final materials = [
        learning_material.LearningMaterial(
          id: '1',
          title: 'Tài liệu hướng dẫn học',
          description: 'Hướng dẫn chi tiết cách học hiệu quả',
          authorId: 'teacher1',
          authorName: 'Giáo viên A',
          type: learning_material.MaterialType.document,
          fileUrl: 'https://example.com/doc1.pdf',
          thumbnailUrl: 'https://example.com/thumbnail1.jpg',
          fileSize: 1024,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
        ),
        learning_material.LearningMaterial(
          id: '2',
          title: 'Video bài giảng tuần 1',
          description: 'Video bài giảng chi tiết tuần 1',
          authorId: 'teacher1',
          authorName: 'Giáo viên A',
          type: learning_material.MaterialType.video,
          fileUrl: 'https://example.com/video1.mp4',
          thumbnailUrl: 'https://example.com/thumbnail2.jpg',
          fileSize: 15360,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 4))),
        ),
        learning_material.LearningMaterial(
          id: '3',
          title: 'Tài liệu tham khảo',
          description: 'Tài liệu bổ sung kiến thức',
          authorId: 'teacher1',
          authorName: 'Giáo viên A',
          type: learning_material.MaterialType.document,
          fileUrl: 'https://example.com/doc2.pdf',
          thumbnailUrl: 'https://example.com/thumbnail3.jpg',
          fileSize: 2048,
          createdAt: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2))),
        ),
      ];
      
      if (!mounted) return;

      setState(() {
        _materials = materials;
        _isLoadingMaterials = false;
        _materialErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingMaterials = false;
        _materialErrorMessage = e.toString();
      });
      
      print('Error loading materials: $e');
    }
  }

  Future<void> _joinClassroom() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Vui lòng đăng nhập để tham gia lớp học';
      }

      await _classroomService.addMember(widget.classroomId, currentUser.uid);

      Get.snackbar(
        'Thành công',
        'Đã tham gia lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );

      _loadClassroom();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _leaveClassroom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rời lớp học'),
          content:
              const Text('Bạn có chắc chắn muốn rời khỏi lớp học này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Rời lớp'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Vui lòng đăng nhập';

      await _classroomService.removeMember(widget.classroomId, currentUser.uid);

      Get.snackbar(
        'Thành công',
        'Đã rời khỏi lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );

      _loadClassroom();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteClassroom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa lớp học'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa lớp học này không? Hành động này không thể hoàn tác.'),
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
      await _classroomService.deleteClassroom(widget.classroomId);

      Get.back(result: true);
      Get.snackbar(
        'Thành công',
        'Đã xóa lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showOptions() {
    if (classroom == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTeacher) ...[
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Thêm bài học mẫu'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      setState(() => _isLoading = true);
                      await _lessonService.addSampleLessons(widget.classroomId);
                      await _loadLessons();
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm các bài học mẫu')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => CreateEditClassroomScreen(
                          classroom: classroom,
                        ));
                    if (result == true) {
                      _loadClassroom();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Quản lý thành viên'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => MemberListScreen(
                          classroom: classroom!,
                        ));
                    if (result == true) {
                      _loadClassroom();
                    }
                  },
                ),
                if (_auth.currentUser?.uid == classroom?.teacherId)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Chia sẻ mã mời'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInviteCode();
                  },
                ),
                if (_auth.currentUser?.uid == classroom?.teacherId)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Xóa lớp học', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteClassroom();
                    },
                  ),
              ] else if (_isMember) ...[
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Rời lớp học', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _leaveClassroom();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteCode() {
    if (classroom?.inviteCode == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mã mời'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                classroom!.inviteCode!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chia sẻ mã này cho người khác để họ có thể tham gia lớp học',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: classroom!.inviteCode!));
                Get.snackbar(
                  'Thành công',
                  'Đã sao chép mã mời',
                  snackPosition: SnackPosition.BOTTOM,
                );
                Navigator.pop(context);
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || classroom == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết lớp học')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
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
                titlePadding: EdgeInsets.lerp(
                    const EdgeInsets.only(left: 16, bottom: 16),
                    const EdgeInsets.only(left: 56, bottom: 16),
                    _scrollOffset),
                collapseMode: CollapseMode.pin,
                background: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _appBarColor,
                        Color.lerp(
                            Colors.blue.shade700,
                            _appBarColorCollapsed..withOpacity(0),
                            _scrollOffset)!,
                      ],
                    ),
                    boxShadow: _isScrolled
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
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
                            color: Colors.white
                                .withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
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
                            color: Colors.white
                                .withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classroom!.description,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${classroom!.memberIds.length} thành viên',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(classroom!.createdAt),
                                      style: const TextStyle(
                                        color: Colors.black,
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: _showOptions,
                ),
              ],
              titleSpacing: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _appBarColor.withOpacity(0),
                    border: Border(
                      bottom: BorderSide(
                        color:
                            Colors.white.withOpacity(_isScrolled ? 0.2 : 0.1),
                        width: _isScrolled ? 1.0 : 0.5,
                      ),
                    ),
                    boxShadow: _isScrolled
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : [],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.menu_book),
                        text: 'Bài học',
                      ),
                      const Tab(
                        icon: Icon(Icons.forum),
                        text: 'Diễn đàn',
                      ),
                      if (_isTeacher)
                        const Tab(
                          icon: Icon(Icons.people),
                          text: 'Thành viên',
                        ),
                      if (_isTeacher)
                        const Tab(
                          icon: Icon(Icons.analytics),
                          text: 'Báo cáo',
                        ),
                    ],
                    unselectedLabelColor: Color(0XFF333333).withOpacity(0.3),
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0XFF333333)),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContentTab(),
            ForumTab(
              classroomId: widget.classroomId,
              isMember: _isMember,
              isTeacher: _isTeacher,
            ),
            if (_isTeacher) _buildMembersTab(),
            if (_isTeacher) ClassroomReportsScreen(
              classroomId: widget.classroomId,
              className: classroom?.name ?? 'Lớp học',
            ),
          ],
        ),
      ),
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              onPressed: _isCourseClosed
                  ? () {
                      Get.snackbar(
                        'Thông báo',
                        'Không thể thêm bài học vì khóa học đã bị khóa',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.shade100,
                        colorText: Colors.orange.shade900,
                      );
                    }
                  : _showAddContentDialog,
              child: const Icon(Icons.add),
              backgroundColor: _isCourseClosed ? Colors.grey : Colors.white,
              tooltip: _isCourseClosed ? 'Khóa học đã bị khóa' : 'Thêm bài học',
            )
          : null,
    );
  }

  Widget _buildContentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin lớp học (2 cột)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cột bên trái - Thông tin giáo viên
                Expanded(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school,
                                size: 24,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Giáo viên',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          teacher?.fullName ?? 'Giáo viên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isTeacher && !_isMember)
                          ElevatedButton.icon(
                            onPressed: _joinClassroom,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Tham gia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              minimumSize: const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else if (!_isTeacher && _isMember)
                          OutlinedButton.icon(
                            onPressed: _leaveClassroom,
                            icon: const Icon(Icons.exit_to_app, size: 18),
                            label: const Text('Rời lớp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 36),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Cột bên phải - Mã lớp học
                if (_isTeacher)
                  Expanded(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.vpn_key,
                                  size: 24,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Mã lớp học',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  classroom!.inviteCode ?? 'Không có mã',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  if (classroom!.inviteCode != null) {
                                    Clipboard.setData(
                                        ClipboardData(text: classroom!.inviteCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Đã sao chép mã lớp học')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showInviteCode,
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Chia sẻ mã lớp'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Danh sách bài học
          if (_isLoadingLessons)
            const Center(child: CircularProgressIndicator())
          else if (_lessonErrorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(_lessonErrorMessage!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLessons,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_lessons.isEmpty)
            Expanded(
              child: _buildEmptyState(
                icon: Icons.menu_book_outlined,
                message: 'Chưa có bài học nào',
                description: 'Giáo viên sẽ thêm bài học vào lớp học này',
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: Colors.indigo.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bài học (${_lessons.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_isTeacher)
                        ElevatedButton.icon(
                          onPressed: () => _showCreateLessonDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Thêm bài học'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _lessons.length,
                      itemBuilder: (context, index) {
                        return _buildLessonCard(_lessons[index], index);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, int index) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                  child: Icon(
                    Icons.article,
                    color: iconColors[colorIndex],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: iconColors[colorIndex],
                        ),
                      ),
                      if (_isTeacher && lesson.approvalStatus != ApprovalStatus.approved)
                        Row(
                          children: [
                            Icon(
                              _getApprovalStatusIcon(lesson.approvalStatus),
                              size: 14,
                              color: _getApprovalStatusColor(lesson.approvalStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lesson.approvalStatus.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getApprovalStatusColor(lesson.approvalStatus),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_isTeacher)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showLessonOptions(lesson),
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
                Text(
                  lesson.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lesson.estimatedMinutes > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.estimatedMinutes} phút',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text(
                    'Tài liệu môn học',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${lesson.folders.length} thư mục',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  children: [
                    if (lesson.folders.isEmpty)
                      ListTile(
                        title: const Text('Chưa có thư mục nào'),
                        subtitle: const Text('Nhấn nút thêm thư mục để tạo mới'),
                        trailing: _isTeacher ? IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showCreateFolderDialog(lesson),
                        ) : null,
                      )
                    else
                      ...lesson.folders.map((folder) => _buildFolderItem(lesson, folder, iconColors[colorIndex])).toList(),
                  ],
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isTeacher)
                      ElevatedButton.icon(
                        onPressed: () => _showCreateFolderDialog(lesson),
                        icon: const Icon(Icons.create_new_folder, size: 16),
                        label: const Text('Thêm thư mục'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _viewLessonDetail(lesson),
                      icon: const Icon(Icons.visibility, size: 16, color: Colors.white),
                      label: const Text('Xem chi tiết', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColors[colorIndex],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildFolderItem(Lesson lesson, LessonFolder folder, Color iconColor) {
    return ListTile(
      leading: Icon(Icons.folder, color: iconColor),
      title: Text(folder.title),
      subtitle: Text(
        '${folder.items.length} mục${folder.description != null ? " • ${folder.description}" : ""}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTeacher)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditFolderDialog(lesson, folder),
            ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => _viewFolderDetail(lesson, folder),
          ),
        ],
      ),
      onTap: () => _viewFolderDetail(lesson, folder),
    );
  }

  Widget _buildMembersTab() {
    if (classroom!.memberIds.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: 'Chưa có học viên nào',
        description: 'Chia sẻ mã lớp học để mời học viên tham gia',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      color: Colors.indigo.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách học viên (${classroom!.memberIds.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => MemberListScreen(classroom: classroom!));
                },
                icon: const Icon(
                  Icons.manage_accounts,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Quản lý',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: classroom!.memberIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<User?>(
                  future: _userService.getUserById(classroom!.memberIds[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Đang tải...'),
                      );
                    }

                    final user = snapshot.data;
                    if (user == null) {
                      return const SizedBox();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatar != null
                              ? NetworkImage(user.avatar!)
                              : null,
                          child: user.avatar == null
                              ? Text(user.firstName![0].toUpperCase())
                              : null,
                        ),
                        title: Text('${user.firstName} ${user.lastName}'),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getRoleText(user),
                                style: TextStyle(
                                  color: _getRoleTextColor(user),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: _isTeacher && user.id != classroom?.teacherId
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: () => _removeMember(user),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(User member) async {
    if (!_isTeacher || member.id == classroom?.teacherId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa thành viên'),
          content: Text(
              'Bạn có chắc chắn muốn xóa ${member.firstName} ${member.lastName} khỏi lớp học không?'),
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
      await _classroomService.removeMember(widget.classroomId, member.id!);

      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });

      Get.snackbar(
        'Thành công',
        'Đã xóa thành viên khỏi lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.indigo.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isTeacher)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: _isCourseClosed
                    ? null
                    : _showAddContentDialog,
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: _isCourseClosed
                    ? const Text(
                        'Khóa học đã bị khóa',
                        style: TextStyle(color: Colors.white),
                      )
                    : const Text(
                        'Thêm bài học',
                        style: TextStyle(color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
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

  void _showAddContentDialog() {
    if (_isCourseClosed) {
      Get.snackbar(
        'Thông báo',
        'Không thể thêm bài học vì khóa học đã bị khóa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }
    _showCreateLessonDialog();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateLessonDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Tạo bài học mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài học',
                hintText: 'Nhập tiêu đề bài học',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả bài học',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Thời gian học (phút)',
                hintText: 'Nhập thời gian dự kiến',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập đầy đủ thông tin',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              final estimatedMinutes = int.tryParse(timeController.text) ?? 0;
              
              try {
                final lesson = Lesson(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  classroomId: widget.classroomId,
                  estimatedMinutes: estimatedMinutes,
                  orderIndex: _lessons.length,
                );
                
                await _lessonService.createLesson(lesson);
                Get.back();
                _loadLessons();
                
                Get.snackbar(
                  'Thành công',
                  'Đã tạo bài học mới',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể tạo bài học: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showEditLessonDialog(Lesson lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final descriptionController = TextEditingController(text: lesson.description);
    final timeController = TextEditingController(text: lesson.estimatedMinutes.toString());
    
    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa bài học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài học',
                hintText: 'Nhập tiêu đề bài học',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả bài học',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Thời gian học (phút)',
                hintText: 'Nhập thời gian dự kiến',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập đầy đủ thông tin',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              final estimatedMinutes = int.tryParse(timeController.text) ?? 0;
              
              try {
                final updatedLesson = lesson.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  estimatedMinutes: estimatedMinutes,
                );
                
                await _lessonService.updateLesson(lesson.id!, updatedLesson);
                Get.back();
                _loadLessons();
                
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật bài học',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể cập nhật bài học: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(Lesson lesson) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Tạo thư mục mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên thư mục',
                hintText: 'Nhập tên thư mục',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Nhập mô tả ngắn gọn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tên thư mục',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              try {
                final folder = LessonFolder(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  orderIndex: lesson.folders.length,
                );
                
                await _lessonService.addFolderToLesson(lesson.id!, folder);
                Get.back();
                _loadLessons();
                
                Get.snackbar(
                  'Thành công',
                  'Đã tạo thư mục mới',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể tạo thư mục: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(Lesson lesson, LessonFolder folder) {
    final folderIndex = lesson.folders.indexWhere((f) => f.title == folder.title && f.orderIndex == folder.orderIndex);
    if (folderIndex == -1) return;
    
    final titleController = TextEditingController(text: folder.title);
    final descriptionController = TextEditingController(text: folder.description);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa thư mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên thư mục',
                hintText: 'Nhập tên thư mục',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Nhập mô tả ngắn gọn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tên thư mục',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              try {
                final updatedFolder = folder.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                
                await _lessonService.updateFolderInLesson(lesson.id!, folderIndex, updatedFolder);
                Get.back();
                _loadLessons();
                
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật thư mục',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể cập nhật thư mục: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderConfirmation(Lesson lesson, int folderIndex) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa thư mục'),
        content: const Text('Bạn có chắc chắn muốn xóa thư mục này? Tất cả bài học trong thư mục sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _lessonService.deleteFolderFromLesson(lesson.id!, folderIndex);
                Get.back();
                _loadLessons();
                
                Get.snackbar(
                  'Thành công',
                  'Đã xóa thư mục',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể xóa thư mục: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLessonConfirmation(Lesson lesson) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa bài học'),
        content: const Text('Bạn có chắc chắn muốn xóa bài học này? Tất cả thư mục và bài học trong bài học sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                print("DEBUG: Bắt đầu xóa bài học: ${lesson.id}");
                await _lessonService.deleteLesson(lesson.id!);
                Get.back();
                
                print("DEBUG: Xóa bài học thành công, tải lại danh sách bài học");
                await _loadLessons();
                
                print("DEBUG: Sau khi tải lại, số lượng bài học: ${_lessons.length}");
                Get.snackbar(
                  'Thành công',
                  'Đã xóa bài học',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                print("DEBUG: Lỗi khi xóa bài học: $e");
                Get.snackbar(
                  'Lỗi',
                  'Không thể xóa bài học: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showLessonOptions(Lesson lesson) {
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
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa bài học'),
              onTap: () {
                Get.back();
                _showEditLessonDialog(lesson);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_copy),
              title: const Text('Thêm thư mục'),
              onTap: () {
                Get.back();
                _showCreateFolderDialog(lesson);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa bài học', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _showDeleteLessonConfirmation(lesson);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewLessonDetail(Lesson lesson) {
    Get.to(() => LessonDetailScreen(
      lessonId: lesson.id!,
      classroomId: widget.classroomId,
    ));
  }

  void _viewFolderDetail(Lesson lesson, LessonFolder folder) {
    final folderIndex = lesson.folders.indexWhere((f) => 
      f.title == folder.title && f.orderIndex == folder.orderIndex);
    
    if (folderIndex == -1) {
      Get.snackbar(
        'Lỗi',
        'Không tìm thấy thư mục',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    Get.to(() => LessonFolderScreen(
      lesson: lesson,
      folder: folder,
      folderIndex: folderIndex,
      isTeacher: _isTeacher,
    ));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // Helper methods for approval status
  IconData _getApprovalStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Icons.pending;
      case ApprovalStatus.approved:
        return Icons.check_circle;
      case ApprovalStatus.rejected:
        return Icons.cancel;
      case ApprovalStatus.revising:
        return Icons.edit_note;
      default:
        return Icons.pending;
    }
  }
  
  Color _getApprovalStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.revising:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _getRoleColor(User user) {
    if (user.roleId == 'admin') {
      return Colors.red.shade100;
    } else if (user.id == classroom?.teacherId || user.roleId == 'teacher') {
      return Colors.blue.shade100;
    }
    return Colors.green.shade100;
  }

  Color _getRoleTextColor(User user) {
    if (user.roleId == 'admin') {
      return Colors.red.shade900;
    } else if (user.id == classroom?.teacherId || user.roleId == 'teacher') {
      return Colors.blue.shade900;
    }
    return Colors.green.shade900;
  }

  String _getRoleText(User user) {
    if (user.roleId == 'admin') {
      return 'Admin';
    } else if (user.id == classroom?.teacherId || user.roleId == 'teacher') {
      return 'Giáo viên';
    }
    return 'Học viên';
  }
}
