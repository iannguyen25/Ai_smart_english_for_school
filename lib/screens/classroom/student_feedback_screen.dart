import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/feedback.dart' as app_models;
import '../../services/feedback_service.dart';
import '../../utils/snackbar_helper.dart';

class StudentFeedbackScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String? lessonId;
  final String? lessonTitle;

  const StudentFeedbackScreen({
    Key? key,
    required this.classId,
    required this.className,
    this.lessonId,
    this.lessonTitle,
  }) : super(key: key);

  @override
  _StudentFeedbackScreenState createState() => _StudentFeedbackScreenState();
}

class _StudentFeedbackScreenState extends State<StudentFeedbackScreen> with TickerProviderStateMixin {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _isSending = false;
  bool _isAnonymous = false;
  app_models.FeedbackType _selectedType = app_models.FeedbackType.question;
  List<File> _selectedAttachments = [];
  List<app_models.Feedback> _myFeedbacks = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyFeedbacks();
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Tải danh sách phản hồi của học sinh
  Future<void> _loadMyFeedbacks() async {
    setState(() => _isLoading = true);
    
    try {
      final feedbacks = await _feedbackService.getCurrentUserFeedbacks();
      
      // Lọc theo lớp học hiện tại
      final filteredFeedbacks = feedbacks
          .where((feedback) => feedback.classId == widget.classId)
          .toList();
      
      setState(() {
        _myFeedbacks = filteredFeedbacks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feedbacks: $e');
      setState(() => _isLoading = false);
      
      SnackbarHelper.showError(
        context: context,
        message: 'Không thể tải phản hồi: ${e.toString()}',
      );
    }
  }
  
  // Chọn hình ảnh từ thư viện
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var imageFile in pickedFiles) {
            _selectedAttachments.add(File(imageFile.path));
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Không thể chọn ảnh: ${e.toString()}',
      );
    }
  }
  
  // Chụp ảnh từ camera
  Future<void> _takePicture() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        setState(() {
          _selectedAttachments.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      print('Error taking picture: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Không thể chụp ảnh: ${e.toString()}',
      );
    }
  }
  
  // Gửi phản hồi
  Future<void> _submitFeedback() async {
    final content = _contentController.text.trim();
    
    // Kiểm tra nội dung
    if (content.isEmpty) {
      SnackbarHelper.showError(
        context: context,
        message: 'Vui lòng nhập nội dung phản hồi',
      );
      return;
    }
    
    if (content.length < 10) {
      SnackbarHelper.showError(
        context: context,
        message: 'Nội dung quá ngắn (ít nhất 10 ký tự)',
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      final feedback = await _feedbackService.createFeedback(
        classId: widget.classId,
        lessonId: widget.lessonId,
        type: _selectedType,
        content: content,
        attachments: _selectedAttachments,
        isAnonymous: _isAnonymous,
      );
      
      if (feedback != null) {
        _contentController.clear();
        setState(() {
          _selectedAttachments = [];
          _isAnonymous = false;
          _selectedType = app_models.FeedbackType.question;
          _isSending = false;
        });
        
        // Cập nhật danh sách phản hồi
        await _loadMyFeedbacks();
        
        // Chuyển sang tab xem phản hồi
        _tabController.animateTo(1);
        
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Gửi phản hồi thành công',
        );
      } else {
        setState(() => _isSending = false);
        
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể gửi phản hồi',
        );
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      setState(() => _isSending = false);
      
      SnackbarHelper.showError(
        context: context,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }
  
  // Xóa hình ảnh đã chọn
  void _removeAttachment(int index) {
    setState(() {
      _selectedAttachments.removeAt(index);
    });
  }
  
  // Format ngày
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phản hồi: ${widget.className}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gửi phản hồi'),
            Tab(text: 'Phản hồi của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendFeedbackTab(),
          _buildMyFeedbacksTab(),
        ],
      ),
    );
  }
  
  // Tab gửi phản hồi
  Widget _buildSendFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin lớp/bài học
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.class_),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lớp: ${widget.className}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.lessonTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.book),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bài học: ${widget.lessonTitle}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Loại phản hồi
          const Text(
            'Loại phản hồi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<app_models.FeedbackType>(
                  isExpanded: true,
                  value: _selectedType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: app_models.FeedbackType.question,
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text('Hỏi bài/Thắc mắc'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: app_models.FeedbackType.report,
                      child: Row(
                        children: [
                          Icon(Icons.report_problem_outlined, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Text('Báo lỗi bài học'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: app_models.FeedbackType.suggestion,
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text('Góp ý cải thiện'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Nội dung phản hồi
          const Text(
            'Nội dung phản hồi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung phản hồi của bạn...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          
          // Đính kèm
          const Text(
            'Đính kèm (tuỳ chọn)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // Hiển thị file đã chọn
                if (_selectedAttachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã chọn ${_selectedAttachments.length} tệp',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _selectedAttachments.length,
                            (index) => Stack(
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedAttachments[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeAttachment(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
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
                  ),
                
                // Nút đính kèm
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Chọn ảnh'),
                          onPressed: _pickImages,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Chụp ảnh'),
                          onPressed: _takePicture,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Ẩn danh
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: CheckboxListTile(
              title: const Text('Gửi ẩn danh'),
              subtitle: const Text(
                'Giáo viên sẽ không biết bạn là ai khi chọn tùy chọn này',
              ),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value ?? false;
                });
              },
            ),
          ),
          
          // Nút gửi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Gửi phản hồi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSending ? null : _submitFeedback,
            ),
          ),
        ],
      ),
    );
  }
  
  // Tab xem phản hồi đã gửi
  Widget _buildMyFeedbacksTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_myFeedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa gửi phản hồi nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy chuyển sang tab "Gửi phản hồi" để gửi phản hồi mới',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMyFeedbacks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myFeedbacks.length,
        itemBuilder: (context, index) {
          final feedback = _myFeedbacks[index];
          return _buildFeedbackItem(feedback);
        },
      ),
    );
  }
  
  // Item hiển thị một phản hồi
  Widget _buildFeedbackItem(app_models.Feedback feedback) {
    // Màu theo trạng thái
    Color statusColor;
    switch (feedback.status) {
      case app_models.FeedbackStatus.pending:
        statusColor = Colors.orange;
        break;
      case app_models.FeedbackStatus.responded:
        statusColor = Colors.blue;
        break;
      case app_models.FeedbackStatus.closed:
        statusColor = Colors.green;
        break;
    }
    
    // Icon theo loại
    IconData typeIcon;
    Color typeColor;
    switch (feedback.type) {
      case app_models.FeedbackType.question:
        typeIcon = Icons.help_outline;
        typeColor = Colors.blue.shade700;
        break;
      case app_models.FeedbackType.report:
        typeIcon = Icons.report_problem_outlined;
        typeColor = Colors.orange.shade700;
        break;
      case app_models.FeedbackType.suggestion:
        typeIcon = Icons.lightbulb_outline;
        typeColor = Colors.green.shade700;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, color: typeColor),
                    const SizedBox(width: 8),
                    Text(
                      feedback.type.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    feedback.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            Divider(color: Colors.grey.shade300, height: 24),
            
            // Content
            Text(
              'Ngày gửi: ${_formatDate(feedback.createdAt?.toDate())}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (feedback.isAnonymous)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đã gửi ẩn danh',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(feedback.content),
            
            // Attachments
            if (feedback.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tệp đính kèm:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        feedback.attachments.length,
                        (index) => GestureDetector(
                          onTap: () {
                            // TODO: Mở ảnh đính kèm
                          },
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                feedback.attachments[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Response from teacher
            if (feedback.response != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.question_answer, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Phản hồi từ giáo viên:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(feedback.response!),
                    const SizedBox(height: 4),
                    Text(
                      'Ngày trả lời: ${_formatDate(feedback.respondedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 