import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/constants.dart';

class NetworkController extends GetxController {
  RxInt connectionStatus = INSTANCE_NETWORK.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> initConnectivity() async {
    ConnectivityResult? result;
    try {
      result = await _connectivity.checkConnectivity();
      print('Result None connect Network: $result');
    } on PlatformException catch (e) {
      print(e.toString());
      result = null;
    }

    await _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult? result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionStatus.value = WIFI_NETWORK;
        break;
      case ConnectivityResult.mobile:
        connectionStatus.value = MOBILE_NETWORK;
        break;
      case ConnectivityResult.none:
        connectionStatus.value = 0;
        break;
      default:
        Get.snackbar('network_error'.tr, 'network_error_message'.tr);
        break;
    }
  }

  @override
  void onClose() {
    super.onClose();
    _connectivitySubscription.cancel();
  }
}
