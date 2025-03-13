import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';

class JoinByCodeScreen extends StatefulWidget {
  const JoinByCodeScreen({Key? key}) : super(key: key);

  @override
  _JoinByCodeScreenState createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends State<JoinByCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _classroomService = ClassroomService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinClassroom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim();
      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        throw 'Vui lòng đăng nhập';
      }

      await _classroomService.joinClassroomByCode(code, currentUser?.id ?? "");

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tham gia lớp học'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nhập mã mời để tham gia lớp học',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã mời',
                  hintText: 'Nhập mã mời 6 ký tự',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã mời';
                  }
                  if (value.length != 6) {
                    return 'Mã mời phải có 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinClassroom,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tham gia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
