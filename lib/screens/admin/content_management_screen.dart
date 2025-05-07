import 'package:base_flutter_framework/screens/flashcards/flashcard_detail_screen.dart';
import 'package:base_flutter_framework/screens/lessons/lesson_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analytics_service.dart';
import '../../utils/snackbar_helper.dart';
import 'package:base_flutter_framework/screens/admin/lesson_preview_screen.dart';
import 'package:base_flutter_framework/screens/admin/flashcard_preview_screen.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({Key? key}) : super(key: key);

  @override
  _ContentManagementScreenState createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic> _resourcesReport = {};
  Map<String, dynamic> _systemOverview = {};
  int _selectedPeriod = 30; // Mặc định 30 ngày
  final List<int> _periodOptions = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadResourcesData();
  }

  Future<void> _loadResourcesData() async {
    setState(() => _isLoading = true);
    
    try {
      // Tải báo cáo tài nguyên học tập
      final resourcesReport = await _analyticsService.getLearningResourcesReport(
        days: _selectedPeriod,
      );
      
      // Tải tổng quan hệ thống để lấy nội dung chờ duyệt
      final systemOverview = await _analyticsService.getSystemOverview(
        days: _selectedPeriod,
      );
      
      print('System Overview: $systemOverview');
      print('Pending Content: ${systemOverview['pendingContent']}');
      
      if (mounted) {
        setState(() {
          _resourcesReport = resourcesReport;
          _systemOverview = systemOverview;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading resources data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể tải dữ liệu tài nguyên: ${e.toString()}',
        );
      }
    }
  }

  void _changePeriod(int days) {
    setState(() {
      _selectedPeriod = days;
    });
    _loadResourcesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nội dung'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Chọn khoảng thời gian',
            icon: const Icon(Icons.date_range),
            onSelected: _changePeriod,
            itemBuilder: (context) => _periodOptions
                .map((days) => PopupMenuItem<int>(
                      value: days,
                      child: Text('$days ngày${_selectedPeriod == days ? ' ✓' : ''}'),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResourcesData,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContentManagement(),
    );
  }

  Widget _buildContentManagement() {
    return RefreshIndicator(
      onRefresh: _loadResourcesData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với thời gian
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Thống kê ${_selectedPeriod} ngày gần đây',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê tài nguyên
            _buildResourcesStats(),
            
            const SizedBox(height: 24),
            
            // Bài học có vấn đề
            if (_resourcesReport.containsKey('problematicLessons') &&
                (_resourcesReport['problematicLessons'] as List).isNotEmpty)
              _buildProblematicLessons(),
            
            const SizedBox(height: 24),
            
            // Nội dung chờ duyệt
            _buildPendingContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesStats() {
    final newResourcesData = [
      {
        'title': 'Bài học',
        'total': _resourcesReport['totalLessons'] ?? 0,
        'new': _resourcesReport['newLessons'] ?? 0,
        'icon': Icons.book,
        'color': Colors.blue,
      },
      {
        'title': 'Flashcards',
        'total': _resourcesReport['totalFlashcards'] ?? 0,
        'new': _resourcesReport['newFlashcards'] ?? 0,
        'icon': Icons.card_membership,
        'color': Colors.green,
      },
      {
        'title': 'Bài tập',
        'total': _resourcesReport['totalExercises'] ?? 0,
        'new': _resourcesReport['newExercises'] ?? 0,
        'icon': Icons.assignment,
        'color': Colors.orange,
      },
      {
        'title': 'Bài kiểm tra',
        'total': _resourcesReport['totalQuizzes'] ?? 0,
        'new': _resourcesReport['newQuizzes'] ?? 0,
        'icon': Icons.quiz,
        'color': Colors.purple,
      },
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thống kê tài nguyên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...newResourcesData.map((resource) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (resource['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      resource['icon'] as IconData,
                      color: resource['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      resource['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (resource['total'] as int).toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if ((resource['new'] as int) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '+${resource['new']}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProblematicLessons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bài học có vấn đề',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_resourcesReport['problematicLessons'] as List).length,
              itemBuilder: (context, index) {
                final lesson = _resourcesReport['problematicLessons'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['lessonTitle'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lesson['reportCount']} báo cáo',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          '${lesson['reportCount']} báo cáo',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingContent() {
    if (_systemOverview['pendingContent'] == null || 
        (_systemOverview['pendingContent'] as List).isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Không có nội dung chờ duyệt',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Nội dung chờ duyệt',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...(_systemOverview['pendingContent'] as List).map((content) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (content['type'] == 'lesson') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonPreviewScreen(
                            lessonId: content['id'],
                          ),
                        ),
                      );
                    } else if (content['type'] == 'flashcard') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardPreviewScreen(
                            flashcardId: content['id'],
                          ),
                        ),
                      );
                    } else if (content['type'] == 'video') {
                      // TODO: Thêm màn hình preview video nếu cần
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: content['type'] == 'lesson' 
                                    ? Colors.blue.withOpacity(0.1)
                                    : content['type'] == 'flashcard'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                content['type'] == 'lesson' 
                                    ? 'Bài học' 
                                    : content['type'] == 'flashcard'
                                        ? 'Flashcard'
                                        : 'Video',
                                style: TextStyle(
                                  color: content['type'] == 'lesson' 
                                      ? Colors.blue
                                      : content['type'] == 'flashcard'
                                          ? Colors.green
                                          : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                content['title'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tác giả: ${content['authorName']}',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        if (content['description'] != null && content['description'].isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            content['description'],
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _rejectContent(content['id']),
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: Text(
                                'Từ chối',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _approveContent(content['id']),
                              icon: Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 18,
                              ),
                              label: Text(
                                'Duyệt',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _approveContent(String contentId) async {
    try {
      // Kiểm tra xem contentId có chứa thông tin về loại nội dung không
      final parts = contentId.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid content ID format');
      }

      final type = parts[0];
      final id = parts[1];
      String collection;
      
      switch (type) {
        case 'lesson':
          collection = 'lessons';
          break;
        case 'flashcard':
          collection = 'flashcards';
          break;
        case 'video':
          collection = 'videos';
          break;
        default:
          throw Exception('Invalid content type');
      }

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      SnackbarHelper.showSuccess(
        context: context,
        message: 'Đã phê duyệt nội dung',
      );
      
      // Refresh data
      _loadResourcesData();
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Không thể phê duyệt nội dung: ${e.toString()}',
      );
    }
  }

  Future<void> _rejectContent(String contentId) async {
    try {
      // Kiểm tra xem contentId có chứa thông tin về loại nội dung không
      final parts = contentId.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid content ID format');
      }

      final type = parts[0];
      final id = parts[1];
      String collection;
      
      switch (type) {
        case 'lesson':
          collection = 'lessons';
          break;
        case 'flashcard':
          collection = 'flashcards';
          break;
        case 'video':
          collection = 'videos';
          break;
        default:
          throw Exception('Invalid content type');
      }

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      SnackbarHelper.showSuccess(
        context: context,
        message: 'Đã từ chối nội dung',
      );
      
      // Refresh data
      _loadResourcesData();
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Không thể từ chối nội dung: ${e.toString()}',
      );
    }
  }
} 