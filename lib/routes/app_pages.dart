import 'package:base_flutter_framework/module/home/binding/home_binding.dart';
import 'package:base_flutter_framework/module/home/view/home_screen.dart';
import 'package:base_flutter_framework/module/splash/binding/splash_binding.dart';
import 'package:base_flutter_framework/module/splash/view/splash_screen.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

const INITIAL = Routes.HOME;

final routePages = [
  GetPage(
    name: Routes.SPLASH,
    page: () => SplashScreen(),
    binding: SplashBinding(),
  ),
  GetPage(
    name: Routes.HOME,
    page: () => HomeScreen(),
    binding: HomeBinding(),
  ),
];
