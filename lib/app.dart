import 'package:base_flutter_framework/module/home/view/home_screen.dart';
import 'package:base_flutter_framework/screens/auth/login_screen.dart';
import 'package:base_flutter_framework/utils/constants/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'base/app_binding.dart';
import 'routes/app_pages.dart';
import 'theme/theme_data.dart';
import 'translations/app_translations_delegate.dart';
import 'translations/application.dart';
import 'utils/constants/colors.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      enableLog: true,
      initialRoute: Routes.SPLASH,
      defaultTransition: Transition.fade,
      getPages: AppPages.routesPages,
      initialBinding: AppBinding(),
      smartManagement: SmartManagement.keepFactory,
      title: APP_NAME,
      theme: ThemeConfig.lightTheme,
      themeMode: ThemeMode.light,
      supportedLocales: application.supportedLocales(),
      localizationsDelegates: [
        AppTranslationsDelegate(newLocale: new Locale('en', '')),
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: EasyLoading.init(builder: (context, widget) {
        return widget!;
      }),
      home: authService.currentUser != null
          ? const HomeScreen()
          : LoginScreen(),
    );
  }
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.threeBounce
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = AppColor.accentColorLight
    ..backgroundColor = AppColor.primaryBackgroundColorLight
    ..indicatorColor = AppColor.primaryColorLight
    ..textColor = AppColor.primaryColorLight
    ..maskColor = AppColor.errorColorLight
    ..userInteractions = false
    ..dismissOnTap = false
    ..animationStyle = EasyLoadingAnimationStyle.scale;
}
