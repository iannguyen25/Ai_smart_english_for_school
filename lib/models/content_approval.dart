import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum ApprovalStatus {
  pending,      // Đang chờ duyệt
  reviewing,    // Đang xem xét
  approved,     // Đã duyệt
  rejected,     // Đã từ chối
  revising,     // Đang chỉnh sửa
  cancelled     // Đã hủy
}

extension ApprovalStatusExtension on ApprovalStatus {
  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Đang chờ duyệt';
      case ApprovalStatus.reviewing:
        return 'Đang xem xét';
      case ApprovalStatus.approved:
        return 'Đã duyệt';
      case ApprovalStatus.rejected:
        return 'Đã từ chối';
      case ApprovalStatus.revising:
        return 'Đang chỉnh sửa';
      case ApprovalStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

enum ApprovalRole {
  creator,      // Người tạo nội dung
  reviewer,     // Người review
  approver      // Người duyệt
}

class ApprovalComment {
  final String userId;         // ID người comment
  final ApprovalRole role;     // Vai trò người comment
  final String content;        // Nội dung comment
  final DateTime createdAt;    // Thời gian tạo
  final List<String> attachments; // File đính kèm

  ApprovalComment({
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
  });

  factory ApprovalComment.fromMap(Map<String, dynamic> map) {
    return ApprovalComment(
      userId: map['userId'] ?? '',
      role: _approvalRoleFromString(map['role'] ?? 'creator'),
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': _approvalRoleToString(role),
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }

  static ApprovalRole _approvalRoleFromString(String role) {
    switch (role) {
      case 'creator':
        return ApprovalRole.creator;
      case 'reviewer':
        return ApprovalRole.reviewer;
      case 'approver':
        return ApprovalRole.approver;
      default:
        return ApprovalRole.creator;
    }
  }

  static String _approvalRoleToString(ApprovalRole role) {
    switch (role) {
      case ApprovalRole.creator:
        return 'creator';
      case ApprovalRole.reviewer:
        return 'reviewer';
      case ApprovalRole.approver:
        return 'approver';
    }
  }
}

class ContentApproval extends BaseModel {
  final String contentId;           // ID của nội dung
  final String versionId;           // ID của version
  final String creatorId;           // ID người tạo
  final List<String> reviewerIds;   // ID người review
  final List<String> approverIds;   // ID người duyệt
  final ApprovalStatus status;      // Trạng thái duyệt
  final DateTime deadline;          // Hạn duyệt
  final List<ApprovalComment> comments; // Các comment
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung

  ContentApproval({
    String? id,
    required this.contentId,
    required this.versionId,
    required this.creatorId,
    required this.reviewerIds,
    required this.approverIds,
    required this.status,
    required this.deadline,
    required this.comments,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ContentApproval.fromMap(Map<String, dynamic> map, String id) {
    return ContentApproval(
      id: id,
      contentId: map['contentId'] ?? '',
      versionId: map['versionId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      reviewerIds: List<String>.from(map['reviewerIds'] ?? []),
      approverIds: List<String>.from(map['approverIds'] ?? []),
      status: _approvalStatusFromString(map['status'] ?? 'pending'),
      deadline: (map['deadline'] as Timestamp).toDate(),
      comments: List<ApprovalComment>.from(
        (map['comments'] ?? []).map((x) => ApprovalComment.fromMap(x))),
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'versionId': versionId,
      'creatorId': creatorId,
      'reviewerIds': reviewerIds,
      'approverIds': approverIds,
      'status': _approvalStatusToString(status),
      'deadline': Timestamp.fromDate(deadline),
      'comments': comments.map((x) => x.toMap()).toList(),
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  static ApprovalStatus _approvalStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'reviewing':
        return ApprovalStatus.reviewing;
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'revising':
        return ApprovalStatus.revising;
      case 'cancelled':
        return ApprovalStatus.cancelled;
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _approvalStatusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'pending';
      case ApprovalStatus.reviewing:
        return 'reviewing';
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.revising:
        return 'revising';
      case ApprovalStatus.cancelled:
        return 'cancelled';
    }
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? contentId,
    String? versionId,
    String? creatorId,
    List<String>? reviewerIds,
    List<String>? approverIds,
    DateTime? deadline,
  }) {
    Map<String, String?> errors = {};

    if (contentId == null || contentId.isEmpty) {
      errors['contentId'] = 'ID nội dung không được để trống';
    }

    if (versionId == null || versionId.isEmpty) {
      errors['versionId'] = 'ID version không được để trống';
    }

    if (creatorId == null || creatorId.isEmpty) {
      errors['creatorId'] = 'ID người tạo không được để trống';
    }

    if (reviewerIds == null || reviewerIds.isEmpty) {
      errors['reviewerIds'] = 'Phải có ít nhất một người review';
    }

    if (approverIds == null || approverIds.isEmpty) {
      errors['approverIds'] = 'Phải có ít nhất một người duyệt';
    }

    if (deadline == null) {
      errors['deadline'] = 'Hạn duyệt không được để trống';
    } else if (deadline.isBefore(DateTime.now())) {
      errors['deadline'] = 'Hạn duyệt phải sau thời điểm hiện tại';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      contentId: contentId,
      versionId: versionId,
      creatorId: creatorId,
      reviewerIds: reviewerIds,
      approverIds: approverIds,
      deadline: deadline,
    );
  }

  // Tạo yêu cầu duyệt mới
  static Future<ContentApproval?> createApproval({
    required String contentId,
    required String versionId,
    required String creatorId,
    required List<String> reviewerIds,
    required List<String> approverIds,
    required DateTime deadline,
    List<ApprovalComment> comments = const [],
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      contentId: contentId,
      versionId: versionId,
      creatorId: creatorId,
      reviewerIds: reviewerIds,
      approverIds: approverIds,
      deadline: deadline,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final approvalDoc = await FirebaseFirestore.instance
          .collection('content_approvals')
          .add({
        'contentId': contentId,
        'versionId': versionId,
        'creatorId': creatorId,
        'reviewerIds': reviewerIds,
        'approverIds': approverIds,
        'status': _approvalStatusToString(ApprovalStatus.pending),
        'deadline': Timestamp.fromDate(deadline),
        'comments': comments.map((x) => x.toMap()).toList(),
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final approvalData = await approvalDoc.get();
      return ContentApproval.fromMap(
        approvalData.data() as Map<String, dynamic>,
        approvalData.id,
      );
    } catch (e) {
      print('Error creating approval: $e');
      return null;
    }
  }

  // Lấy yêu cầu duyệt theo nội dung
  static Future<List<ContentApproval>> getApprovalsByContent(
    String contentId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_approvals')
          .where('contentId', isEqualTo: contentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContentApproval.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting approvals: $e');
      return [];
    }
  }

  // Lấy yêu cầu duyệt theo người duyệt
  static Future<List<ContentApproval>> getApprovalsByUser(
    String userId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_approvals')
          .where('reviewerIds', arrayContains: userId)
          .orderBy('deadline')
          .get();

      return snapshot.docs
          .map((doc) => ContentApproval.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user approvals: $e');
      return [];
    }
  }

  // Thêm comment
  Future<bool> addComment(ApprovalComment comment) async {
    try {
      if (id == null) return false;

      final updatedComments = [...comments, comment];

      await FirebaseFirestore.instance
          .collection('content_approvals')
          .doc(id)
          .update({
        'comments': updatedComments.map((x) => x.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Cập nhật trạng thái
  Future<bool> updateStatus(ApprovalStatus newStatus) async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_approvals')
          .doc(id)
          .update({
        'status': _approvalStatusToString(newStatus),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  // Duyệt nội dung
  Future<bool> approve({
    required String approverId,
    required String comment,
  }) async {
    try {
      if (id == null) return false;
      if (!approverIds.contains(approverId)) return false;

      final approvalComment = ApprovalComment(
        userId: approverId,
        role: ApprovalRole.approver,
        content: comment,
        createdAt: DateTime.now(),
      );

      final success = await addComment(approvalComment);
      if (!success) return false;

      return await updateStatus(ApprovalStatus.approved);
    } catch (e) {
      print('Error approving content: $e');
      return false;
    }
  }

  // Từ chối duyệt
  Future<bool> reject({
    required String approverId,
    required String reason,
  }) async {
    try {
      if (id == null) return false;
      if (!approverIds.contains(approverId)) return false;

      final rejectionComment = ApprovalComment(
        userId: approverId,
        role: ApprovalRole.approver,
        content: reason,
        createdAt: DateTime.now(),
      );

      final success = await addComment(rejectionComment);
      if (!success) return false;

      return await updateStatus(ApprovalStatus.rejected);
    } catch (e) {
      print('Error rejecting content: $e');
      return false;
    }
  }

  // Hủy yêu cầu duyệt
  Future<bool> cancel({
    required String userId,
    String? reason,
  }) async {
    try {
      if (id == null) return false;
      if (userId != creatorId) return false;

      if (reason != null) {
        final cancelComment = ApprovalComment(
          userId: userId,
          role: ApprovalRole.creator,
          content: reason,
          createdAt: DateTime.now(),
        );

        final success = await addComment(cancelComment);
        if (!success) return false;
      }

      return await updateStatus(ApprovalStatus.cancelled);
    } catch (e) {
      print('Error cancelling approval: $e');
      return false;
    }
  }

  @override
  ContentApproval copyWith({
    String? id,
    String? contentId,
    String? versionId,
    String? creatorId,
    List<String>? reviewerIds,
    List<String>? approverIds,
    ApprovalStatus? status,
    DateTime? deadline,
    List<ApprovalComment>? comments,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ContentApproval(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      versionId: versionId ?? this.versionId,
      creatorId: creatorId ?? this.creatorId,
      reviewerIds: reviewerIds ?? this.reviewerIds,
      approverIds: approverIds ?? this.approverIds,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      comments: comments ?? this.comments,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 