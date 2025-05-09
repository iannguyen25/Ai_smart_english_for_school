import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/badge.dart' as models;
import '../../services/badge_service.dart';
import '../../services/storage_service.dart';

class BadgeManagementScreen extends StatefulWidget {
  const BadgeManagementScreen({Key? key}) : super(key: key);

  @override
  State<BadgeManagementScreen> createState() => _BadgeManagementScreenState();
}

class _BadgeManagementScreenState extends State<BadgeManagementScreen> {
  final BadgeService _badgeService = BadgeService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconUrlController = TextEditingController();
  models.BadgeType _selectedType = models.BadgeType.misc;
  bool _isHidden = false;
  bool _isOneTime = true;
  
  // Image file
  File? _imageFile;
  bool _isUploading = false;
  
  // Requirements map
  final Map<String, dynamic> _requirements = {};
  
  // Badge being edited
  models.Badge? _editingBadge;
  
  @override
  void initState() {
    super.initState();
    _resetForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    setState(() => _isUploading = true);
    
    try {
      final imageUrl = await _storageService.uploadImage(_imageFile!, 'badges');
      setState(() => _isUploading = false);
      return imageUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh lên: $e')),
      );
      return null;
    }
  }
  
  void _addRequirement(String key, dynamic value) {
    setState(() {
      _requirements[key] = value;
    });
  }
  
  void _removeRequirement(String key) {
    setState(() {
      _requirements.remove(key);
    });
  }
  
  void _startEditing(models.Badge badge) {
    setState(() {
      _editingBadge = badge;
      _nameController.text = badge.name;
      _descriptionController.text = badge.description;
      _iconUrlController.text = badge.iconUrl;
      _selectedType = badge.type;
      _isHidden = badge.isHidden;
      _isOneTime = badge.isOneTime;
      _requirements.clear();
      _requirements.addAll(badge.requirements);
      _imageFile = null;
    });
  }
  
  Future<void> _updateBadge() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingBadge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy huy hiệu cần cập nhật')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    String? iconUrl = _iconUrlController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    try {
      // Nếu có ảnh mới được chọn, tải lên và lấy URL
      if (_imageFile != null) {
        final newImageUrl = await _uploadImage();
        if (newImageUrl != null) {
          iconUrl = newImageUrl;
        }
      }

      if (iconUrl == null || iconUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh cho huy hiệu')),
        );
        return;
      }

      final badge = await _badgeService.updateBadge(
        badgeId: _editingBadge!.id!,
        name: name,
        description: description,
        iconUrl: iconUrl,
        type: _selectedType,
        requirements: _requirements,
        isHidden: _isHidden,
        isOneTime: _isOneTime,
      );

      if (badge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật huy hiệu thành công')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật huy hiệu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<void> _deleteBadge(models.Badge badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa huy hiệu "${badge.name}"?'),
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
      ),
    );
    
    if (confirmed == true) {
      try {
        // Xóa ảnh từ Storage
        await _storageService.deleteImage(badge.iconUrl);
        
        final success = await _badgeService.deleteBadge(badge.id ?? '');
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa huy hiệu thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa huy hiệu đang được sử dụng')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
  
  Future<void> _createBadge() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    try {
      // Tải ảnh lên và lấy URL
      final iconUrl = await _uploadImage();
      if (iconUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh cho huy hiệu')),
        );
        return;
      }

      final badge = await _badgeService.createBadge(
        name: name,
        description: description,
        iconUrl: iconUrl,
        type: _selectedType,
        requirements: _requirements,
        isHidden: _isHidden,
        isOneTime: _isOneTime,
      );

      if (badge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo huy hiệu thành công')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo huy hiệu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  void _resetForm() {
    setState(() {
      _editingBadge = null;
      _nameController.clear();
      _descriptionController.clear();
      _iconUrlController.clear();
      _selectedType = models.BadgeType.misc;
      _isHidden = false;
      _isOneTime = true;
      _requirements.clear();
      _imageFile = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý huy hiệu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form tạo/sửa huy hiệu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingBadge != null ? 'Sửa huy hiệu' : 'Tạo huy hiệu mới',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tên huy hiệu
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên huy hiệu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên huy hiệu';
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
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Chọn ảnh
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ảnh huy hiệu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (_imageFile != null)
                                    Expanded(
                                      child: Image.file(
                                        _imageFile!,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  else if (_editingBadge != null)
                                    Expanded(
                                      child: Image.network(
                                        _editingBadge!.iconUrl,
                                        height: 100,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image, size: 100);
                                        },
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _isUploading ? null : _pickImage,
                                    icon: const Icon(Icons.image),
                                    label: Text(_isUploading ? 'Đang tải...' : 'Chọn ảnh'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Loại huy hiệu
                      DropdownButtonFormField<models.BadgeType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại huy hiệu',
                          border: OutlineInputBorder(),
                        ),
                        items: models.BadgeType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Các tùy chọn
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Ẩn huy hiệu'),
                              value: _isHidden,
                              onChanged: (value) {
                                setState(() {
                                  _isHidden = value ?? false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Chỉ nhận một lần'),
                              value: _isOneTime,
                              onChanged: (value) {
                                setState(() {
                                  _isOneTime = value ?? true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Phần điều kiện
                      const Text(
                        'Điều kiện đạt được',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Hiển thị các điều kiện hiện tại
                      ..._requirements.entries.map((entry) {
                        return Card(
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text(entry.value.toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeRequirement(entry.key),
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Thêm điều kiện mới
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Tên điều kiện',
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _addRequirement(value, 0);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Giá trị',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    final key = _requirements.keys.last;
                                    _addRequirement(key, int.tryParse(value) ?? 0);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nút tạo/sửa huy hiệu
                      Row(
                        children: [
                          if (_editingBadge != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _resetForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Hủy'),
                              ),
                            ),
                          if (_editingBadge != null)
                            const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : (_editingBadge != null ? _updateBadge : _createBadge),
                              child: Text(_editingBadge != null ? 'Cập nhật' : 'Tạo huy hiệu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Danh sách huy hiệu hiện có
            const Text(
              'Danh sách huy hiệu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('badges').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Có lỗi xảy ra');
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final badge = models.Badge.fromMap(data, doc.id);
                    
                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          badge.iconUrl,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.emoji_events);
                          },
                        ),
                        title: Text(badge.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(badge.description),
                            Text('Loại: ${badge.type.label}'),
                            Text('Điều kiện: ${badge.requirements}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _startEditing(badge),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteBadge(badge),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 