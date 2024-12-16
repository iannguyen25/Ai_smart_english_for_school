import 'package:base_flutter_framework/app.dart';
import 'package:base_flutter_framework/base/di.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  runApp(App());
  configLoading();
}
