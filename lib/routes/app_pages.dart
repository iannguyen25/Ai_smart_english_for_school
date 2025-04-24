import 'package:get/get.dart';
import '../screens/exercises/create_exercise_screen.dart';
import '../screens/home/home_screen.dart' as app_home;
import '../screens/splash/splash_screen.dart';

abstract class Routes {
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const EXERCISES_CREATE = '/exercises/create';
}

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routesPages = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const app_home.HomeScreen(),
    )
  ];
}
