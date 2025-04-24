import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/learning_material.dart' as learning_material;
import 'package:firebase_auth/firebase_auth.dart' as auth;

class MaterialsTab extends StatefulWidget {
  final String classroomId;
  final bool isMember;
  final bool isTeacher;
  
  const MaterialsTab({
    Key? key,
    required this.classroomId,
    required this.isMember,
    required this.isTeacher,
  }) : super(key: key);
  
  @override
  _MaterialsTabState createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<MaterialsTab> {
  final _auth = auth.FirebaseAuth.instance;
  
  List<learning_material.LearningMaterial> _materials = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }
  
  // Tải dữ liệu tài liệu
  Future<void> _loadMaterials() async {
    try {
      setState(() => _isLoading = true);
      
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
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      print('Error loading materials: $e');
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
              onPressed: _loadMaterials,
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
                  'Tài liệu lớp học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài liệu bổ sung cho lớp học',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (widget.isTeacher)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddMaterialDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tài liệu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Materials list
          Expanded(
            child: _materials.isEmpty
                ? _buildEmptyState(
                    icon: Icons.folder_outlined,
                    message: 'Chưa có tài liệu nào',
                    description: widget.isTeacher
                        ? 'Hãy thêm tài liệu cho lớp học'
                        : 'Giáo viên sẽ thêm tài liệu cho lớp học',
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _materials.length,
                    itemBuilder: (context, index) {
                      final material = _materials[index];
                      return _buildMaterialItem(material);
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
  
  // Hiển thị một item tài liệu
  Widget _buildMaterialItem(learning_material.LearningMaterial material) {
    // Icon dựa vào loại tài liệu
    IconData materialIcon;
    Color materialColor;
    
    switch (material.type) {
      case learning_material.MaterialType.document:
        materialIcon = Icons.description;
        materialColor = Colors.blue;
        break;
      case learning_material.MaterialType.video:
        materialIcon = Icons.videocam;
        materialColor = Colors.red;
        break;
      case learning_material.MaterialType.audio:
        materialIcon = Icons.headphones;
        materialColor = Colors.orange;
        break;
      case learning_material.MaterialType.image:
        materialIcon = Icons.image;
        materialColor = Colors.green;
        break;
      case learning_material.MaterialType.link:
        materialIcon = Icons.link;
        materialColor = Colors.purple;
        break;
      default:
        materialIcon = Icons.folder;
        materialColor = Colors.grey;
    }
    
    return Container(
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
            // Mở chi tiết tài liệu
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail hoặc icon
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: materialColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: material.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          material.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              materialIcon,
                              size: 40,
                              color: materialColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          materialIcon,
                          size: 40,
                          color: materialColor,
                        ),
                      ),
              ),
              
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      material.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Type and size badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: materialColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            material.typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: materialColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (material.fileSizeFormatted != null)
                          Text(
                            material.fileSizeFormatted!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
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
  
  // Hiển thị hộp thoại thêm tài liệu
  void _showAddMaterialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tài liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.red.shade400),
              title: const Text('Video bài giảng'),
              onTap: () {
                Navigator.pop(context);
                // Chuyển đến màn hình thêm video
                Get.toNamed('/materials/videos/create', arguments: {
                  'classroomId': widget.classroomId
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.style, color: Colors.orange.shade400),
              title: const Text('Thẻ ghi nhớ'),
              onTap: () {
                Navigator.pop(context);
                // Chuyển đến màn hình tạo flashcard
                Get.toNamed('/flashcards/create', arguments: {
                  'classroomId': widget.classroomId
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.book, color: Colors.green.shade400),
              title: const Text('Bài học'),
              onTap: () {
                Navigator.pop(context);
                // Tạo bài học mới
                _showCreateLessonDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.upload_file, color: Colors.blue.shade400),
              title: const Text('Tài liệu tham khảo'),
              onTap: () {
                Navigator.pop(context);
                // Chuyển đến màn hình upload tài liệu
                Get.toNamed('/materials/upload', arguments: {
                  'classroomId': widget.classroomId
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  // Hiển thị dialog tạo bài học mới
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
                // Gọi service để tạo bài học
                final firestore = FirebaseFirestore.instance;
                final _auth = auth.FirebaseAuth.instance;
                
                await firestore.collection('lessons').add({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'classroomId': widget.classroomId,
                  'estimatedMinutes': estimatedMinutes,
                  'orderIndex': 0, // Sẽ cập nhật sau
                  'approvalStatus': 'pending',
                  'teacherId': _auth.currentUser?.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                Get.back();
                
                // Reload materials
                _loadMaterials();
                
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
}
