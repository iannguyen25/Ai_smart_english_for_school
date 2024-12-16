import 'package:base_flutter_framework/components/bindings/network_binding.dart';
import 'package:get/get.dart';

class AppBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    Get
      ..put(NetworkBinding(),
          permanent: true); // keep the class in memory with "permanent:true"
  }
}
