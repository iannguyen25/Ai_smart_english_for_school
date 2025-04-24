import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/learning_material.dart' as lm;
import '../../services/auth_service.dart';
import '../../services/material_service.dart';
import 'create_edit_material_screen.dart';
import 'material_details_screen.dart';

class TeacherMaterialsScreen extends StatefulWidget {
  const TeacherMaterialsScreen({Key? key}) : super(key: key);

  @override
  _TeacherMaterialsScreenState createState() => _TeacherMaterialsScreenState();
}

class _TeacherMaterialsScreenState extends State<TeacherMaterialsScreen> {
  final AuthService _authService = AuthService();
  final MaterialService _materialService = MaterialService();
  
  List<lm.LearningMaterial> _materials = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading materials for teacher...');
      final user = _authService.currentUser;
      if (user == null || user.id == null) {
        setState(() {
          _errorMessage = 'Không thể xác định thông tin người dùng';
          _isLoading = false;
        });
        print('User not found: ${user?.id}');
        return;
      }

      print('Current user ID: ${user.id}');
      final materials = await lm.LearningMaterial.getMaterialsByAuthor(user.id ?? '');
      print('Loaded ${materials.length} materials');
      
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading materials: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Không thể tải danh sách tài liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMaterial(lm.LearningMaterial material) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài liệu "${material.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (material.id == null) {
          throw Exception('ID tài liệu không hợp lệ');
        }
        
        await _materialService.deleteMaterial(material.id!);
        
        
          setState(() {
            _materials.removeWhere((item) => item.id == material.id);
            _isLoading = false;
          });
          
          Get.snackbar(
            'Thành công',
            'Đã xóa tài liệu "${material.title}"',
            snackPosition: SnackPosition.BOTTOM,
          );
        
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        Get.snackbar(
          'Lỗi',
          'Không thể xóa tài liệu: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _showMaterialOptions(lm.LearningMaterial material) {
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
              leading: const Icon(Icons.visibility),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Get.back();
                Get.to(() => MaterialDetailsScreen(material: material));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Get.back();
                Get.to(() => CreateEditMaterialScreen(material: material))?.then((result) {
                  if (result == true) {
                    _loadMaterials();
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Sao chép đường dẫn'),
              onTap: () {
                Get.back();
                // Giả lập copy đường dẫn
                Get.snackbar(
                  'Thông báo',
                  'Đã sao chép đường dẫn tài liệu vào bộ nhớ tạm',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _deleteMaterial(material);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building TeacherMaterialsScreen with: isLoading=$_isLoading, errorMessage=$_errorMessage, materials=${_materials.length}");
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
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
                      Icon(Icons.error_outline, 
                          size: 48, color: Colors.red.shade300),
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
                )
              : _materials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder, 
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Bạn chưa có tài liệu nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => const CreateEditMaterialScreen())?.then((result) {
                                if (result == true) {
                                  _loadMaterials();
                                }
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo tài liệu mới'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMaterials,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _materials.length,
                        itemBuilder: (context, index) {
                          final material = _materials[index];
                          return _buildMaterialCard(material);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreateEditMaterialScreen())?.then((result) {
            if (result == true) {
              _loadMaterials();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Tạo tài liệu mới',
      ),
    );
  }

  Widget _buildMaterialCard(lm.LearningMaterial material) {
    // Format thời gian để hiển thị
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdDate = dateFormat.format(material.createdAt?.toDate() ?? DateTime.now());

    // Màu nền dựa vào loại tài liệu
    Color cardColor;
    IconData typeIcon;
    
    switch (material.type) {
      case lm.MaterialType.document:
        cardColor = Colors.blue.shade50;
        typeIcon = Icons.description;
        break;
      case lm.MaterialType.video:
        cardColor = Colors.red.shade50;
        typeIcon = Icons.video_library;
        break;
      case lm.MaterialType.audio:
        cardColor = Colors.purple.shade50;
        typeIcon = Icons.audiotrack;
        break;
      case lm.MaterialType.image:
        cardColor = Colors.green.shade50;
        typeIcon = Icons.image;
        break;
      case lm.MaterialType.link:
        cardColor = Colors.orange.shade50;
        typeIcon = Icons.link;
        break;
      default:
        cardColor = Colors.grey.shade50;
        typeIcon = Icons.folder;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Get.to(() => MaterialDetailsScreen(material: material)),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với loại tài liệu và thời gian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        material.typeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    createdDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Nội dung chính
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail hoặc icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: material.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              material.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                typeIcon,
                                size: 30,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          )
                        : Icon(
                            typeIcon,
                            size: 30,
                            color: Colors.grey.shade700,
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          material.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Thông tin phụ
                        Row(
                          children: [
                            if (material.fileSize != null) ...[
                              Icon(
                                Icons.data_usage,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                material.fileSizeFormatted ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.download,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${material.downloads} lượt tải',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              material.isPublic ? Icons.public : Icons.lock,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              material.isPublic ? 'Công khai' : 'Riêng tư',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu button
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showMaterialOptions(material),
                  ),
                ],
              ),
            ),
            
            // Hiển thị tags nếu có
            if (material.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: material.tags.map((tag) => Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 