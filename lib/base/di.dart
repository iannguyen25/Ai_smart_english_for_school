import 'package:base_flutter_framework/services/storage_service.dart';
import 'package:base_flutter_framework/utils/hive_database/dao/image_cache_dao.dart';
import 'package:base_flutter_framework/utils/hive_database/hive_database.dart';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:path_provider/path_provider.dart';

class DependencyInjection {
  static Future<void> init() async {
    await Get.putAsync(() => StorageService().init());
    final dir = await getApplicationDocumentsDirectory();
    final _hive = HiveDatabase(dir.path);
    await _hive.init();
    Get.put(ImageCacheDAO(_hive.imageCacheBox), permanent: true);
  }
}
