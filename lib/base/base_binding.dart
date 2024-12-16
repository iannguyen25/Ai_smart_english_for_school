import 'package:base_flutter_framework/components/controllers/network_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class BaseBinding implements Bindings {
  @override
  @mustCallSuper
  void dependencies() {
    Get.lazyPut<NetworkController>(() => NetworkController());
  }
}
