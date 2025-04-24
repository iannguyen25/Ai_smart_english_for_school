import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart' as app_models;

class EditProfileScreen extends StatefulWidget {
  final app_models.User user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  String? _avatarUrl;
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName ?? "";
    _lastNameController.text = widget.user.lastName ?? "";
    _avatarUrl = widget.user.avatar;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _avatarUrl;

    try {
      print('Starting avatar upload for user: ${widget.user.id}');
      
      final fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child(widget.user.id!)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': widget.user.id!},
      );

      String avatarUrl = '';
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          print('Upload attempt ${retryCount + 1}');
          
          final uploadTask = storageRef.putFile(_imageFile!, metadata);
          
          final subscription = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
            
            if (mounted) {
              // Có thể thêm code để hiển thị tiến trình ở đây nếu cần
            }
          });
          
          _subscriptions.add(subscription);
          
          await uploadTask;
          
          subscription.cancel();
          _subscriptions.remove(subscription);
          
          avatarUrl = await storageRef.getDownloadURL();
          print('Avatar uploaded successfully: $avatarUrl');
          return avatarUrl;
        } catch (e) {
          retryCount++;
          print('Upload attempt failed: $e');
          if (retryCount >= maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
      
      return null;
    } catch (e) {
      print('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh lên: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? avatarUrl;
      if (_imageFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang tải ảnh lên...')),
          );
        }
        
        avatarUrl = await _uploadImage();
        
        if (!mounted) return;
        
        if (avatarUrl == null && _imageFile != null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Không thể tải ảnh lên. Vui lòng thử lại sau.';
          });
          return;
        }
      }

      print('Updating profile with avatar URL: $avatarUrl');
      
      final result = await _authService.updateUserProfile(
        userId: widget.user.id!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        avatar: avatarUrl ?? _avatarUrl,
      );

      if (!mounted) return;

      if (result.success) {
        Get.back(result: result.user);
        Get.snackbar(
          'Thành công',
          'Thông tin cá nhân đã được cập nhật',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Không thể cập nhật thông tin';
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Profile picture
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? NetworkImage(_avatarUrl!)
                                    : null),
                            child: (_imageFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh đại diện'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (_imageFile != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Xóa ảnh đã chọn', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên của bạn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ của bạn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Cập nhật thông tin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
