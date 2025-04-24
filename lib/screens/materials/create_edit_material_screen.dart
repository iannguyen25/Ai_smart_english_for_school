import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../models/learning_material.dart' as lm;
import '../../services/auth_service.dart';
import '../../services/material_service.dart';

class CreateEditMaterialScreen extends StatefulWidget {
  final lm.LearningMaterial? material;

  const CreateEditMaterialScreen({Key? key, this.material}) : super(key: key);

  @override
  _CreateEditMaterialScreenState createState() => _CreateEditMaterialScreenState();
}

class _CreateEditMaterialScreenState extends State<CreateEditMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _urlController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final MaterialService _materialService = MaterialService();
  
  bool _isLoading = false;
  // Dữ liệu của tài liệu
  lm.MaterialType _selectedType = lm.MaterialType.document;
  bool _isPublic = true;
  List<String> _tags = [];
  // Tệp đã chọn
  File? _selectedFile;
  String? _selectedFileName;
  int? _selectedFileSize;
  
  // Ảnh xem trước (nếu là hình ảnh)
  File? _previewImage;

  @override
  void initState() {
    super.initState();
    
    // Nếu là chỉnh sửa, điền dữ liệu hiện có
    if (widget.material != null) {
      _titleController.text = widget.material!.title;
      _descriptionController.text = widget.material!.description;
      _selectedType = widget.material!.type;
      _isPublic = widget.material!.isPublic;
      _tags = List<String>.from(widget.material!.tags);
      _tagsController.text = _tags.join(', ');
      
      if (widget.material!.type == lm.MaterialType.link && widget.material!.fileUrl != null) {
        _urlController.text = widget.material!.fileUrl!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.material != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Cập nhật tài liệu' : 'Tạo tài liệu mới'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveForm,
              icon: const Icon(Icons.check),
              label: const Text('Lưu'),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loại tài liệu
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Loại tài liệu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildMaterialTypeChip(
                                  lm.MaterialType.document,
                                  'Tài liệu',
                                  Icons.description,
                                  Colors.blue,
                                ),
                                _buildMaterialTypeChip(
                                  lm.MaterialType.video,
                                  'Video',
                                  Icons.video_library,
                                  Colors.red,
                                ),
                                _buildMaterialTypeChip(
                                  lm.MaterialType.audio,
                                  'Âm thanh',
                                  Icons.audiotrack,
                                  Colors.purple,
                                ),
                                _buildMaterialTypeChip(
                                  lm.MaterialType.image,
                                  'Hình ảnh',
                                  Icons.image,
                                  Colors.green,
                                ),
                                _buildMaterialTypeChip(
                                  lm.MaterialType.link,
                                  'Đường dẫn',
                                  Icons.link,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Thông tin cơ bản
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin cơ bản',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Tiêu đề
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập tiêu đề';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Mô tả
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mô tả';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Tags
                            TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Thẻ (phân cách bởi dấu phẩy)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                                hintText: 'tiếng anh, ngữ pháp, tiếng nhật',
                              ),
                            ),
                            
                            // Quyền truy cập
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Hiển thị công khai: '),
                                Switch(
                                  value: _isPublic,
                                  onChanged: (value) {
                                    setState(() {
                                      _isPublic = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tải lên tệp hoặc nhập URL
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedType == lm.MaterialType.link
                                  ? 'Đường dẫn tài liệu'
                                  : 'Tải lên tài liệu',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_selectedType == lm.MaterialType.link) ...[
                              // Nhập URL
                              TextFormField(
                                controller: _urlController,
                                decoration: const InputDecoration(
                                  labelText: 'URL',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                  hintText: 'https://example.com/resource',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập URL';
                                  }
                                  if (!Uri.parse(value).isAbsolute) {
                                    return 'URL không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              // Tải lên tệp
                              _selectedFile != null || _selectedFileName != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Hiển thị thông tin tệp đã chọn
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    _getFileIcon(),
                                                    color: _getFileColor(),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _selectedFileName ?? 'Tệp đã chọn',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (_selectedFileSize != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    'Kích thước: ${_formatFileSize(_selectedFileSize!)}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              
                                              // Xem trước nếu là hình ảnh
                                              if (_selectedType == lm.MaterialType.image && _previewImage != null) ...[
                                                const SizedBox(height: 16),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    _previewImage!,
                                                    height: 200,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        
                                        // Nút chọn tệp khác
                                        TextButton.icon(
                                          onPressed: _pickFile,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Chọn tệp khác'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300, width: 1),
                                          ),
                                          child: InkWell(
                                            onTap: _pickFile,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.cloud_upload,
                                                  size: 48,
                                                  color: Colors.blue.shade300,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Nhấn để chọn tệp',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                if (_selectedType == lm.MaterialType.image)
                                                  const Text(
                                                    'Hỗ trợ: JPG, PNG, GIF',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  )
                                                else if (_selectedType == lm.MaterialType.video)
                                                  const Text(
                                                    'Hỗ trợ: MP4, MOV, AVI',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  )
                                                else if (_selectedType == lm.MaterialType.audio)
                                                  const Text(
                                                    'Hỗ trợ: MP3, WAV, M4A',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  )
                                                else if (_selectedType == lm.MaterialType.document)
                                                  const Text(
                                                    'Hỗ trợ: PDF, DOC, DOCX, PPT',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMaterialTypeChip(lm.MaterialType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, color: isSelected ? Colors.white : color),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            // Đặt lại tệp đã chọn nếu thay đổi loại
            _selectedFile = null;
            _selectedFileName = null;
            _selectedFileSize = null;
            _previewImage = null;
          });
        }
      },
    );
  }

  IconData _getFileIcon() {
    switch (_selectedType) {
      case lm.MaterialType.document:
        return Icons.description;
      case lm.MaterialType.video:
        return Icons.video_library;
      case lm.MaterialType.audio:
        return Icons.audiotrack;
      case lm.MaterialType.image:
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (_selectedType) {
      case lm.MaterialType.document:
        return Colors.blue;
      case lm.MaterialType.video:
        return Colors.red;
      case lm.MaterialType.audio:
        return Colors.purple;
      case lm.MaterialType.image:
        return Colors.green;
      case lm.MaterialType.link:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _pickFile() async {
    try {
      if (_selectedType == lm.MaterialType.image) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        
        if (pickedFile != null) {
          // Tạo bản sao trong thư mục tạm
          final tempDir = await getTemporaryDirectory();
          final fileName = path.basename(pickedFile.path);
          final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
          final targetPath = "${tempDir.path}/$uniqueFileName";
          
          // Đọc file gốc và tạo file mới
          final sourceFile = File(pickedFile.path);
          final bytes = await sourceFile.readAsBytes();
          final copiedFile = File(targetPath);
          await copiedFile.writeAsBytes(bytes);
          
          // Kiểm tra file mới đã tồn tại
          if (!copiedFile.existsSync()) {
            throw Exception('Không thể tạo bản sao file');
          }
          
          final fileSize = await copiedFile.length();
          
          setState(() {
            _selectedFile = copiedFile;
            _selectedFileName = fileName;
            _selectedFileSize = fileSize;
            _previewImage = copiedFile;
          });
          
          print("File sao chép tại: ${copiedFile.path}");
          print("File tồn tại: ${copiedFile.existsSync()}");
        }
      } else {
        // Xác định loại tệp được phép
        List<String>? allowedExtensions;
        
        if (_selectedType == lm.MaterialType.document) {
          allowedExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'];
        } else if (_selectedType == lm.MaterialType.video) {
          allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
        } else if (_selectedType == lm.MaterialType.audio) {
          allowedExtensions = ['mp3', 'wav', 'm4a', 'flac', 'aac'];
        }
        
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final platformFile = result.files.first;
          
          if (platformFile.path != null) {
            // Tạo bản sao trong thư mục tạm
            final tempDir = await getTemporaryDirectory();
            final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}";
            final targetPath = "${tempDir.path}/$uniqueFileName";
            
            // Đọc file gốc và tạo file mới
            final sourceFile = File(platformFile.path!);
            final bytes = await sourceFile.readAsBytes();
            final copiedFile = File(targetPath);
            await copiedFile.writeAsBytes(bytes);
            
            // Kiểm tra file mới đã tồn tại
            if (!copiedFile.existsSync()) {
              throw Exception('Không thể tạo bản sao file');
            }
            
            final fileSize = await copiedFile.length();
            
            setState(() {
              _selectedFile = copiedFile;
              _selectedFileName = platformFile.name;
              _selectedFileSize = fileSize;
            });
            
            print("File sao chép tại: ${copiedFile.path}");
            print("File tồn tại: ${copiedFile.existsSync()}");
          }
        }
      }
    } catch (e) {
      print("Lỗi khi chọn file: $e");
      Get.snackbar(
        'Lỗi',
        'Không thể chọn tệp: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Kiểm tra xem đã chọn tệp chưa (không áp dụng cho loại link)
    if (_selectedType != lm.MaterialType.link && _selectedFile == null && widget.material?.fileUrl == null) {
      Get.snackbar(
        'Thông báo',
        'Vui lòng chọn tệp để tải lên',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Lấy tags từ controller
    final tagsText = _tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      _tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } else {
      _tags = [];
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tạo hoặc cập nhật tài liệu
      lm.LearningMaterial material = widget.material?.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        isPublic: _isPublic,
        tags: _tags,
      ) ?? lm.LearningMaterial(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        authorId: _authService.currentUser?.id ?? '',
        authorName: _authService.currentUser?.fullName ?? '',
        isPublic: _isPublic,
        tags: _tags,
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      
      // URL từ tệp hoặc từ trường nhập liệu
      String? fileUrl;
      
      if (_selectedType == lm.MaterialType.link) {
        fileUrl = _urlController.text.trim();
      } else if (_selectedFile != null) {
        // Kiểm tra file có tồn tại không
        if (!_selectedFile!.existsSync()) {
          throw Exception('File không tồn tại hoặc đã bị xóa. Vui lòng chọn lại file.');
        }
        
        // Tải lên tệp và lấy URL
        fileUrl = await _materialService.uploadFile(
          _selectedFile!,
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName ?? 'file'}',
        );
        
        // Cập nhật kích thước tệp
        material = material.copyWith(
          fileSize: _selectedFileSize,
        );
        
        // Nếu là hình ảnh, lưu URL làm hình xem trước
        if (_selectedType == lm.MaterialType.image) {
          material = material.copyWith(
            thumbnailUrl: fileUrl,
          );
        }
      }
      
      // Cập nhật URL tệp (nếu có)
      if (fileUrl != null) {
        material = material.copyWith(
          fileUrl: fileUrl,
        );
      }
      
      // Lưu vào Firestore
      if (widget.material?.id != null) {
        await _materialService.updateMaterial(widget.material!.id!, material);
      } else {
        await _materialService.createMaterial(material);
      }
      
      // Trở về màn hình trước với kết quả thành công
      Get.back(result: true);
      
      Get.snackbar(
        'Thành công',
        widget.material != null 
            ? 'Đã cập nhật tài liệu thành công'
            : 'Đã tạo tài liệu thành công',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể lưu tài liệu: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 