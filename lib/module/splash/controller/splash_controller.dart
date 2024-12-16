import 'package:base_flutter_framework/utils/constants/common.dart';
import 'package:base_flutter_framework/utils/constants/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  Future<void> onInit() async {
    super.onInit();
    //send token and user id to server

    await loadInitSplashScreen();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
  }

  Future<void> loadInitSplashScreen() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final storage = Get.find<SharedPreferences>();
    _loadLanguage(storage);
    _loadTheme(storage);
    await Get.offAllNamed(Routes.HOME);
  }

  void _loadLanguage(SharedPreferences storage) {
    final language = storage.getString(StorageConstants.language);
    if (language == null) {
      Get.updateLocale(const Locale('vi', 'VN'));
      storage.setString(StorageConstants.language, VIETNAMESE_LANG);
      return;
    }

    if (language == VIETNAMESE_LANG) {
      Get.updateLocale(const Locale('vi', 'VN'));
      return;
    }

    Get.updateLocale(const Locale('en', 'US'));
  }

  void _loadTheme(SharedPreferences storage) {
    final theme = storage.getString(StorageConstants.theme);
    if (theme == null || theme == LIGHT_THEME) {
      Get.changeThemeMode(ThemeMode.light);
      storage.setString(StorageConstants.theme, LIGHT_THEME);
      return;
    }

    Get.changeThemeMode(ThemeMode.dark);
    storage.setString(StorageConstants.theme, DARK_THEME);
  }

  // void handleNotificationInteractive(NotificationPayload payload) {
  //   print('=>>>>>> $payload');
  // }
}
