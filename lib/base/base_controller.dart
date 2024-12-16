import 'package:base_flutter_framework/network/managers/network_manager.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';

class BaseController extends GetxController with NetworkManager {
  final _hasNetworkSubject = BehaviorSubject<bool>();

  Stream<bool> get hasNetworkStream => _hasNetworkSubject.stream;

  Sink<bool> get hasNetworkSink => _hasNetworkSubject.sink;

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _hasNetworkSubject.close();
  }
}
