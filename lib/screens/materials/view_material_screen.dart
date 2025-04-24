import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import '../../constants.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';

class ViewMaterialScreenArguments {
  final String materialId;
  final String materialName;

  ViewMaterialScreenArguments({
    required this.materialId,
    required this.materialName,
  });
}

class ViewMaterialScreen extends StatefulWidget {
  static const routeName = '/view-material';

  const ViewMaterialScreen({Key? key}) : super(key: key);

  @override
  State<ViewMaterialScreen> createState() => _ViewMaterialScreenState();
}

class _ViewMaterialScreenState extends State<ViewMaterialScreen> {
  late ViewMaterialScreenArguments args;
  bool isLoading = true;
  bool isDownloading = false;
  double downloadProgress = 0;
  String? errorMessage;
  Map<String, dynamic>? materialData;
  String? localFilePath;
  bool isPDF = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as ViewMaterialScreenArguments;
    _loadMaterialData();
  }

  Future<void> _loadMaterialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .doc(args.materialId)
          .get();

      if (!docSnapshot.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'Tài liệu không tồn tại hoặc đã bị xóa.';
        });
        return;
      }

      final data = docSnapshot.data()!;
      setState(() {
        materialData = data;
        isLoading = false;
        // Kiểm tra nếu file là PDF
        if (data['fileUrl'] != null && data['fileUrl'].toString().toLowerCase().endsWith('.pdf')) {
          isPDF = true;
        }
      });

      // Nếu là PDF thì tự động download
      if (isPDF) {
        await _downloadFile();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Đã xảy ra lỗi khi tải thông tin tài liệu: $e';
      });
    }
  }

  Future<void> _downloadFile() async {
    if (materialData == null || materialData!['fileUrl'] == null) {
      setState(() {
        errorMessage = 'Không có file để tải xuống.';
      });
      return;
    }

    setState(() {
      isDownloading = true;
      downloadProgress = 0;
    });

    try {
      // Yêu cầu quyền lưu trữ trên Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          setState(() {
            isDownloading = false;
            errorMessage = 'Cần cấp quyền lưu trữ để tải xuống file.';
          });
          return;
        }
      }

      final fileUrl = materialData!['fileUrl'] as String;
      final fileName = fileUrl.split('/').last;
      
      // Lấy thư mục tạm để lưu file
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      
      // Kiểm tra xem file đã tồn tại chưa
      final file = File(filePath);
      if (await file.exists()) {
        setState(() {
          localFilePath = filePath;
          isDownloading = false;
        });
        return;
      }

      // Sử dụng Dio để tải file và theo dõi tiến trình
      final dio = Dio();
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        localFilePath = filePath;
        isDownloading = false;
      });
    } catch (e) {
      setState(() {
        isDownloading = false;
        errorMessage = 'Đã xảy ra lỗi khi tải xuống file: $e';
      });
    }
  }

  Future<void> _openFile() async {
    if (localFilePath == null) {
      await _downloadFile();
      if (localFilePath == null) return;
    }

    try {
      final result = await OpenFile.open(localFilePath!);
      if (result.type != ResultType.done) {
        setState(() {
          errorMessage = 'Không thể mở file: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Đã xảy ra lỗi khi mở file: $e';
      });
    }
  }

  Future<void> _shareDocument() async {
    if (localFilePath == null) {
      await _downloadFile();
      if (localFilePath == null) return;
    }

    try {
      await Share.shareXFiles(
        [XFile(localFilePath!)],
        text: 'Chia sẻ tài liệu: ${materialData!['name']}',
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Đã xảy ra lỗi khi chia sẻ tài liệu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: args.materialName,
        showBackButton: true,
      ),
      body: isLoading 
          ? const Center(child: LoadingIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Thử lại',
                          onPressed: _loadMaterialData,
                          backgroundColor: kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (materialData == null) {
      return const Center(child: Text('Không có thông tin tài liệu.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin tài liệu
          Text(
            materialData!['name'] ?? 'Không có tên',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (materialData!['description'] != null)
            Text(
              materialData!['description'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 16),
          
          // Hiển thị thời gian tạo
          if (materialData!['createdAt'] != null)
            Text(
              'Ngày tạo: ${_formatDate(materialData!['createdAt'])}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
          const SizedBox(height: 24),
          
          // Phần xem tài liệu
          Expanded(
            child: isPDF && localFilePath != null
                ? PDFView(
                    filePath: localFilePath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    fitPolicy: FitPolicy.BOTH,
                    onError: (error) {
                      setState(() {
                        errorMessage = 'Lỗi khi hiển thị PDF: $error';
                      });
                    },
                  )
                : Center(
                    child: isDownloading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: downloadProgress > 0 ? downloadProgress : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Đang tải xuống... ${(downloadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.description,
                                size: 80,
                                color: kPrimaryColor,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tài liệu sẵn sàng để xem hoặc tải xuống',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Tải xuống',
                                      onPressed: _downloadFile,
                                      backgroundColor: kPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Mở file',
                                      onPressed: _openFile,
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Chia sẻ tài liệu',
                                onPressed: _shareDocument,
                                backgroundColor: Colors.blue,
                                icon: Icons.share,
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Không có thông tin';
  }
} 