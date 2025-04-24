import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class to display snackbar messages in the app
class SnackbarHelper {
  /// Display a success message with green background
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Display an error message with red background
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Display an info message with blue background
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Alternative implementation using GetX for global access without context
  static void showSuccessGetX({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      'Thành công',
      message,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Alternative implementation using GetX for global access without context
  static void showErrorGetX({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      'Lỗi',
      message,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Alternative implementation using GetX for global access without context
  static void showInfoGetX({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      'Thông báo',
      message,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
} 