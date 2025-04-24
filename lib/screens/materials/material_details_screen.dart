import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import '../../models/learning_material.dart' as lm;
import '../../services/auth_service.dart';
import '../../services/material_service.dart';
import 'create_edit_material_screen.dart';

class MaterialDetailsScreen extends StatefulWidget {
  final lm.LearningMaterial material;

  const MaterialDetailsScreen({Key? key, required this.material}) : super(key: key);

  @override
  _MaterialDetailsScreenState createState() => _MaterialDetailsScreenState();
}

class _MaterialDetailsScreenState extends State<MaterialDetailsScreen> {
  final AuthService _authService = AuthService();
  final MaterialService _materialService = MaterialService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdDate = dateFormat.format(widget.material.createdAt?.toDate() ?? DateTime.now());
    
    // Xác định icon và màu cho loại tài liệu
    IconData typeIcon;
    Color typeColor;
    
    switch (widget.material.type) {
      case lm.MaterialType.document:
        typeIcon = Icons.description;
        typeColor = Colors.blue;
        break;
      case lm.MaterialType.video:
        typeIcon = Icons.video_library;
        typeColor = Colors.red;
        break;
      case lm.MaterialType.audio:
        typeIcon = Icons.audiotrack;
        typeColor = Colors.purple;
        break;
      case lm.MaterialType.image:
        typeIcon = Icons.image;
        typeColor = Colors.green;
        break;
      case lm.MaterialType.link:
        typeIcon = Icons.link;
        typeColor = Colors.orange;
        break;
      default:
        typeIcon = Icons.folder;
        typeColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          // Nếu là tác giả hoặc admin, hiện nút chỉnh sửa và xóa
          if (widget.material.authorId == _authService.currentUser?.id || 
              _authService.isCurrentUserAdmin)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Get.to(() => CreateEditMaterialScreen(material: widget.material))?.then((value) {
                      if (value == true) {
                        // Reload material
                        setState(() {});
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDeleteMaterial,
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Giả lập chia sẻ tài liệu
              Get.snackbar(
                'Thông báo',
                'Đã sao chép đường dẫn tài liệu vào bộ nhớ tạm',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Loại tài liệu và ngày tạo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(widget.material.typeLabel),
                                avatar: Icon(typeIcon, color: typeColor),
                                backgroundColor: typeColor.withOpacity(0.1),
                              ),
                              Text(
                                'Tạo ngày: $createdDate',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Tiêu đề
                          Text(
                            widget.material.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Tác giả
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Tác giả: ${widget.material.authorName ?? "Không xác định"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Mô tả
                          const Text(
                            'Mô tả:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.material.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Xem trước nội dung
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nội dung tài liệu:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Hiển thị nội dung tùy theo loại
                          _buildContentPreview(widget.material, typeIcon, typeColor),
                          
                          // Thông tin phụ
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.material.downloads} lượt tải',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.material.fileSize != null)
                                Text(
                                  'Kích thước: ${widget.material.fileSizeFormatted}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (widget.material.tags.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thẻ:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.material.tags.map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.grey.shade200,
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: widget.material.fileUrl != null
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _downloadMaterial,
                  icon: const Icon(Icons.download),
                  label: const Text('Tải xuống'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContentPreview(lm.LearningMaterial material, IconData typeIcon, Color typeColor) {
    if (material.thumbnailUrl != null && material.type == lm.MaterialType.image) {
      // Hiển thị hình ảnh
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          material.thumbnailUrl!,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 48, color: typeColor),
                    const SizedBox(height: 8),
                    const Text('Không thể tải hình ảnh'),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Hiển thị icon dựa vào loại tài liệu
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(typeIcon, size: 64, color: typeColor),
              const SizedBox(height: 16),
              Text(
                'Nội dung ${material.typeLabel.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (material.fileUrl != null) ...[
                const SizedBox(height: 8),
                const Text('Nhấn nút tải xuống để xem tài liệu'),
              ],
            ],
          ),
        ),
      );
    }
  }

  Future<void> _downloadMaterial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tăng số lượt tải
      if (widget.material.id != null) {
        await _materialService.incrementDownloadCount(widget.material.id!);
      }

      // Mở URL tài liệu
      if (widget.material.fileUrl != null) {
        final Uri url = Uri.parse(widget.material.fileUrl!);
        
        try {
          // Thử mở bằng url_launcher
          if (await canLaunchUrl(url)) {
            await launchUrl(
              url, 
              mode: LaunchMode.externalApplication,
            );
          } else {
            // Nếu không mở được, thử tải về thiết bị trước
            await _downloadFile(widget.material.fileUrl!, widget.material.title);
          }
        } catch (e) {
          // Nếu có lỗi, thử phương pháp tải xuống thay thế
          await _downloadFile(widget.material.fileUrl!, widget.material.title);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải tài liệu: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Tải file về thiết bị và mở
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Tạo tên file từ URL
      final fileExtension = url.split('.').last.split('?').first;
      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final String fullFileName = '$safeFileName.$fileExtension';
      
      // Lấy đường dẫn thư mục tải xuống
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fullFileName';
      
      // Hiển thị thông báo bắt đầu tải
      Get.snackbar(
        'Đang tải xuống',
        'Vui lòng đợi trong giây lát...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
      // Tải xuống file bằng Dio
      await Dio().download(
        url, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Đã tải: $progress%');
          }
        }
      );
      
      final file = File(filePath);
      if (await file.exists()) {
        // Hiển thị dialog với các tùy chọn 
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Tải xuống thành công'),
              content: const Text('Bạn muốn làm gì với tệp đã tải?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Đóng'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Chia sẻ file
                    Share.shareXFiles(
                      [XFile(filePath)],
                      text: 'Chia sẻ "${widget.material.title}"',
                    );
                  },
                  child: const Text('Chia sẻ'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Thông báo đường dẫn đã lưu
                    Get.snackbar(
                      'Thông tin',
                      'Tệp đã được lưu tại: $filePath',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 5),
                    );
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error downloading file: $e');
      throw 'Không thể tải xuống tệp: ${e.toString()}';
    }
  }

  void _confirmDeleteMaterial() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              setState(() {
                _isLoading = true;
              });
              try {
                if (widget.material.id != null) {
                  await _materialService.deleteMaterial(widget.material.id!);
                  Get.back(result: true);
                  Get.snackbar(
                    'Thành công',
                    'Đã xóa tài liệu',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  throw Exception('ID tài liệu không hợp lệ');
                }
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
} 