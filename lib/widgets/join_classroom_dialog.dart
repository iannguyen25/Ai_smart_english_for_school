import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/classroom_service.dart';
import '../services/auth_service.dart';

class JoinClassroomDialog extends StatefulWidget {
  const JoinClassroomDialog({Key? key}) : super(key: key);

  @override
  _JoinClassroomDialogState createState() => _JoinClassroomDialogState();
}

class _JoinClassroomDialogState extends State<JoinClassroomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _joinClassroom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        throw 'Vui lòng đăng nhập';
      }

      await _classroomService.joinClassroomByCode(
        _codeController.text.trim(),
        currentUser?.id ?? "",
      );

      Get.back(result: true);
      Get.snackbar(
        'Thành công',
        'Đã tham gia lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tham gia lớp học'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Mã mời',
                hintText: 'Nhập mã mời để tham gia lớp học',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mã mời';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinClassroom,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Tham gia'),
        ),
      ],
    );
  }
}
