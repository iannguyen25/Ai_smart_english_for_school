import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum BackupType {
  full,       // Sao lưu toàn bộ
  partial,    // Sao lưu một phần
  automatic,  // Sao lưu tự động
  manual      // Sao lưu thủ công
}

enum BackupStatus {
  pending,    // Đang chờ
  running,    // Đang chạy
  completed,  // Hoàn thành
  failed,     // Thất bại
  restored    // Đã khôi phục
}

class BackupMetadata {
  final int totalItems;        // Tổng số item
  final int processedItems;    // Số item đã xử lý
  final List<String> errors;   // Danh sách lỗi
  final Map<String, int> stats;// Thống kê theo loại

  BackupMetadata({
    required this.totalItems,
    required this.processedItems,
    this.errors = const [],
    this.stats = const {},
  });

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      totalItems: map['totalItems'] ?? 0,
      processedItems: map['processedItems'] ?? 0,
      errors: List<String>.from(map['errors'] ?? []),
      stats: Map<String, int>.from(map['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalItems': totalItems,
      'processedItems': processedItems,
      'errors': errors,
      'stats': stats,
    };
  }

  double get progressPercent => 
    totalItems > 0 ? (processedItems / totalItems * 100) : 0;
}

class ContentBackup extends BaseModel {
  final String name;              // Tên bản sao lưu
  final String description;       // Mô tả
  final BackupType type;          // Loại sao lưu
  final BackupStatus status;      // Trạng thái
  final String creatorId;         // ID người tạo
  final List<String> collections; // Danh sách collection
  final String storageUrl;        // URL lưu trữ
  final BackupMetadata metadata;  // Metadata
  final Map<String, dynamic>? data;// Dữ liệu sao lưu

  ContentBackup({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.creatorId,
    required this.collections,
    required this.storageUrl,
    required this.metadata,
    this.data,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ContentBackup.fromMap(Map<String, dynamic> map, String id) {
    return ContentBackup(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: _backupTypeFromString(map['type'] ?? 'manual'),
      status: _backupStatusFromString(map['status'] ?? 'pending'),
      creatorId: map['creatorId'] ?? '',
      collections: List<String>.from(map['collections'] ?? []),
      storageUrl: map['storageUrl'] ?? '',
      metadata: BackupMetadata.fromMap(map['metadata'] ?? {}),
      data: map['data'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': _backupTypeToString(type),
      'status': _backupStatusToString(status),
      'creatorId': creatorId,
      'collections': collections,
      'storageUrl': storageUrl,
      'metadata': metadata.toMap(),
      'data': data,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  static BackupType _backupTypeFromString(String type) {
    switch (type) {
      case 'full':
        return BackupType.full;
      case 'partial':
        return BackupType.partial;
      case 'automatic':
        return BackupType.automatic;
      case 'manual':
        return BackupType.manual;
      default:
        return BackupType.manual;
    }
  }

  static String _backupTypeToString(BackupType type) {
    switch (type) {
      case BackupType.full:
        return 'full';
      case BackupType.partial:
        return 'partial';
      case BackupType.automatic:
        return 'automatic';
      case BackupType.manual:
        return 'manual';
    }
  }

  static BackupStatus _backupStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return BackupStatus.pending;
      case 'running':
        return BackupStatus.running;
      case 'completed':
        return BackupStatus.completed;
      case 'failed':
        return BackupStatus.failed;
      case 'restored':
        return BackupStatus.restored;
      default:
        return BackupStatus.pending;
    }
  }

  static String _backupStatusToString(BackupStatus status) {
    switch (status) {
      case BackupStatus.pending:
        return 'pending';
      case BackupStatus.running:
        return 'running';
      case BackupStatus.completed:
        return 'completed';
      case BackupStatus.failed:
        return 'failed';
      case BackupStatus.restored:
        return 'restored';
    }
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? name,
    String? description,
    String? creatorId,
    List<String>? collections,
  }) {
    Map<String, String?> errors = {};

    if (name == null || name.isEmpty) {
      errors['name'] = 'Tên bản sao lưu không được để trống';
    } else if (name.length > 100) {
      errors['name'] = 'Tên bản sao lưu không được quá 100 ký tự';
    }

    if (description != null && description.length > 500) {
      errors['description'] = 'Mô tả không được quá 500 ký tự';
    }

    if (creatorId == null || creatorId.isEmpty) {
      errors['creatorId'] = 'ID người tạo không được để trống';
    }

    if (collections == null || collections.isEmpty) {
      errors['collections'] = 'Phải chọn ít nhất một collection để sao lưu';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      name: name,
      description: description,
      creatorId: creatorId,
      collections: collections,
    );
  }

  // Tạo bản sao lưu mới
  static Future<ContentBackup?> createBackup({
    required String name,
    required String description,
    required String creatorId,
    required List<String> collections,
    required BackupType type,
    Map<String, dynamic>? data,
  }) async {
    final errors = validate(
      name: name,
      description: description,
      creatorId: creatorId,
      collections: collections,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final metadata = BackupMetadata(
        totalItems: 0,
        processedItems: 0,
      );

      final backupDoc = await FirebaseFirestore.instance
          .collection('content_backups')
          .add({
        'name': name,
        'description': description,
        'type': _backupTypeToString(type),
        'status': _backupStatusToString(BackupStatus.pending),
        'creatorId': creatorId,
        'collections': collections,
        'storageUrl': '',
        'metadata': metadata.toMap(),
        'data': data,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final backupData = await backupDoc.get();
      return ContentBackup.fromMap(
        backupData.data() as Map<String, dynamic>,
        backupData.id,
      );
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }

  // Lấy danh sách bản sao lưu
  static Future<List<ContentBackup>> getBackups() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_backups')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContentBackup.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }

  // Lấy bản sao lưu theo ID
  static Future<ContentBackup?> getBackupById(String backupId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('content_backups')
          .doc(backupId)
          .get();

      if (!doc.exists) return null;

      return ContentBackup.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting backup: $e');
      return null;
    }
  }

  // Cập nhật trạng thái
  Future<bool> updateStatus(BackupStatus newStatus) async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_backups')
          .doc(id)
          .update({
        'status': _backupStatusToString(newStatus),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  // Cập nhật metadata
  Future<bool> updateMetadata(BackupMetadata newMetadata) async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_backups')
          .doc(id)
          .update({
        'metadata': newMetadata.toMap(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating metadata: $e');
      return false;
    }
  }

  // Cập nhật URL lưu trữ
  Future<bool> updateStorageUrl(String url) async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_backups')
          .doc(id)
          .update({
        'storageUrl': url,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating storage URL: $e');
      return false;
    }
  }

  // Xóa bản sao lưu
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_backups')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }

  // Khôi phục từ bản sao lưu
  Future<bool> restore() async {
    try {
      if (id == null) return false;
      if (status != BackupStatus.completed) return false;
      if (data == null) return false;

      // TODO: Implement restore logic here
      // 1. Validate backup data
      // 2. Create restore point of current data
      // 3. Apply backup data to collections
      // 4. Update status to restored
      
      return await updateStatus(BackupStatus.restored);
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  @override
  ContentBackup copyWith({
    String? id,
    String? name,
    String? description,
    BackupType? type,
    BackupStatus? status,
    String? creatorId,
    List<String>? collections,
    String? storageUrl,
    BackupMetadata? metadata,
    Map<String, dynamic>? data,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ContentBackup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      collections: collections ?? this.collections,
      storageUrl: storageUrl ?? this.storageUrl,
      metadata: metadata ?? this.metadata,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 