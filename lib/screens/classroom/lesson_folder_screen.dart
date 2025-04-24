import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
import '../../models/learning_material.dart' as lm;
import '../../services/material_service.dart';

class LessonFolderScreen extends StatefulWidget {
  final Lesson lesson;
  final LessonFolder folder;
  final int folderIndex;
  final bool isTeacher;

  const LessonFolderScreen({
    Key? key,
    required this.lesson,
    required this.folder,
    required this.folderIndex,
    required this.isTeacher,
  }) : super(key: key);

  @override
  _LessonFolderScreenState createState() => _LessonFolderScreenState();
}

class _LessonFolderScreenState extends State<LessonFolderScreen> {
  final LessonService _lessonService = LessonService();
  final MaterialService _materialService = MaterialService();

  bool _isLoading = false;
  late LessonFolder _folder;
  List<lm.LearningMaterial> _materials = [];

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Chỉ tải các tài liệu học tập có trong thư mục này
      final List<String?> materialIds = _folder.items
          .where((item) => item.materialId != null)
          .map((item) => item.materialId)
          .toList();

      final List<lm.LearningMaterial> materials = [];
      for (final id in materialIds) {
        if (id != null) {
          final material = await _materialService.getMaterialById(id);
          if (material != null) {
            materials.add(material);
          }
        }
      }

      if (!mounted) return;
      
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading materials: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      Get.snackbar(
        'Lỗi',
        'Không thể tải tài liệu: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showAddContentDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    
    LessonItemType selectedType = LessonItemType.document;
    String? selectedMaterialId;
    lm.LearningMaterial? selectedMaterial;
    
    await Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm nội dung'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loại nội dung
                  const Text(
                    'Loại nội dung:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in LessonItemType.values)
                        ChoiceChip(
                          label: Text(type.label),
                          selected: selectedType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedType = type;
                                if (type != LessonItemType.document && 
                                    type != LessonItemType.video &&
                                    type != LessonItemType.audio) {
                                  selectedMaterialId = null;
                                  selectedMaterial = null;
                                }
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      hintText: 'Nhập tiêu đề nội dung',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (tùy chọn)',
                      hintText: 'Nhập mô tả ngắn gọn',
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  if (selectedType == LessonItemType.video ||
                      selectedType == LessonItemType.audio)
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        hintText: 'Nhập đường dẫn',
                      ),
                    ),
                  
                  if (selectedType == LessonItemType.document ||
                      selectedType == LessonItemType.video ||
                      selectedType == LessonItemType.audio) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Liên kết tài liệu: (tùy chọn)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // TODO: Hiển thị dialog chọn tài liệu
                        Get.back(result: 'select_material');
                      },
                      icon: const Icon(Icons.link),
                      label: Text(selectedMaterial?.title ?? 'Chọn tài liệu'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) {
                    Get.snackbar(
                      'Lỗi',
                      'Vui lòng nhập tiêu đề',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  
                  if ((selectedType == LessonItemType.video ||
                       selectedType == LessonItemType.audio) && 
                      urlController.text.isEmpty && 
                      selectedMaterialId == null) {
                    Get.snackbar(
                      'Lỗi',
                      'Vui lòng nhập URL hoặc chọn tài liệu',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  
                  Get.back(result: {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'type': selectedType,
                    'url': urlController.text.trim(),
                    'materialId': selectedMaterialId,
                  });
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    ).then((result) async {
      if (result == null) return;
      
      if (result == 'select_material') {
        // TODO: Hiển thị màn hình chọn tài liệu
        return;
      }
      
      try {
        final item = LessonItem(
          title: result['title'],
          description: result['description'],
          type: result['type'],
          content: result['url'] ?? '',
          materialId: result['materialId'], 
        );
        
        await _lessonService.addItemToFolder(widget.lesson.id!, widget.folderIndex, item);
        
        // Cập nhật dữ liệu
        final updatedLesson = await _lessonService.getLessonById(widget.lesson.id!);
        if (updatedLesson != null && mounted) {
          setState(() {
            _folder = updatedLesson.folders[widget.folderIndex];
          });
        }
        
        Get.snackbar(
          'Thành công',
          'Đã thêm nội dung mới',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        print('Error adding item: $e');
        Get.snackbar(
          'Lỗi',
          'Không thể thêm nội dung: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  Future<void> _deleteItem(int itemIndex) async {
    try {
      await _lessonService.deleteItemFromFolder(
          widget.lesson.id!, widget.folderIndex, itemIndex);

      // Cập nhật dữ liệu
      final updatedLesson = await _lessonService.getLessonById(widget.lesson.id!);
      if (updatedLesson != null && mounted) {
        setState(() {
          _folder = updatedLesson.folders[widget.folderIndex];
        });
      }

      Get.snackbar(
        'Thành công',
        'Đã xóa nội dung',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error deleting item: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa nội dung: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Color _getItemColor(LessonItemType type) {
    switch (type) {
      case LessonItemType.document:
        return Colors.blue;
      case LessonItemType.exercise:
        return Colors.green;
      case LessonItemType.vocabulary:
        return Colors.purple;
      case LessonItemType.video:
        return Colors.red;
      case LessonItemType.audio:
        return Colors.orange;
      case LessonItemType.quiz:
        return Colors.amber;
    }
  }

  IconData _getItemIcon(LessonItemType type) {
    switch (type) {
      case LessonItemType.document:
        return Icons.insert_drive_file;
      case LessonItemType.exercise:
        return Icons.assignment;
      case LessonItemType.vocabulary:
        return Icons.menu_book;
      case LessonItemType.video:
        return Icons.videocam;
      case LessonItemType.audio:
        return Icons.audiotrack;
      case LessonItemType.quiz:
        return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_folder.title),
        actions: [
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddContentDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folder.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có nội dung nào',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thêm nội dung để bắt đầu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.isTeacher)
                        ElevatedButton.icon(
                          onPressed: _showAddContentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm nội dung'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _folder.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _folder.items[index];
                    final color = _getItemColor(item.type);
                    final icon = _getItemIcon(item.type);
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: item.description != null
                            ? Text(
                                item.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: widget.isTeacher
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(index),
                              )
                            : null,
                        onTap: () {
                          lm.LearningMaterial? material;
                          if (item.materialId != null) {
                            material = _materials.firstWhereOrNull(
                              (m) => m.id == item.materialId,
                            );
                          }

                          switch (item.type) {
                            case LessonItemType.document:
                              if (material != null) {
                                Get.toNamed('/document-viewer', arguments: material);
                              } else if (item.content.isNotEmpty) {
                                Get.toNamed('/document-viewer', arguments: {'url': item.content});
                              }
                              break;
                              
                            case LessonItemType.video:
                              if (material != null) {
                                Get.toNamed('/video-player', arguments: material);
                              } else if (item.content.isNotEmpty) {
                                Get.toNamed('/video-player', arguments: {'url': item.content});
                              }
                              break;
                              
                            case LessonItemType.audio:
                              if (material != null) {
                                Get.toNamed('/audio-player', arguments: material);
                              } else if (item.content.isNotEmpty) {
                                Get.toNamed('/audio-player', arguments: {'url': item.content});
                              }
                              break;
                              
                            case LessonItemType.exercise:
                              Get.toNamed('/exercise', arguments: item);
                              break;
                              
                            case LessonItemType.vocabulary:
                              Get.toNamed('/vocabulary', arguments: item);
                              break;
                              
                            case LessonItemType.quiz:
                              Get.toNamed('/quiz', arguments: item);
                              break;
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 