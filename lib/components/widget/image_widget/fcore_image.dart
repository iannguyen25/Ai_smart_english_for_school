import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'fcore_image_controller.dart';
import 'skeleton_widget.dart';

class FCoreImage extends StatelessWidget {
  FCoreImage(
    this.source, {
    Key? key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.usePlaceHolder = false,
    this.color,
    this.saveToLocal = false,
  }) : super(key: key);

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool usePlaceHolder;
  final Color? color;
  final bool saveToLocal;

  final _cacheImageController = CacheImageController();

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return const Placeholder();
    }

    if (source.contains('http')) {
      final cacheFile = _cacheImageController.imageCacheDAO.getByUrl(source);
      if (cacheFile == null) {
        _cacheImageController.downloadFile(source);
      } else {
        _cacheImageController.filename.value = cacheFile.filePath;
      }
      if (source.endsWith('.svg')) {
        return Obx(
          () => _cacheImageController.filename.value.isNotEmpty
              ? SvgPicture.file(
                  File(_cacheImageController.filename.value),
                  width: width,
                  height: height,
                )
              : usePlaceHolder
                  ? const Skeleton()
                  : const SizedBox(),
        );
      }

      return Obx(() => _cacheImageController.filename.value.isNotEmpty
          ? ExtendedImage.file(
              File(_cacheImageController.filename.value),
              fit: fit,
              width: width,
              height: height,
            )
          : usePlaceHolder
              ? const Skeleton()
              : const SizedBox());
    }
    if (source.contains('.svg')) {
      return SvgPicture.asset(
        source,
        fit: fit,
        color: color,
        width: width,
        height: height,
      );
    }
    return Image.asset(
      source,
      fit: fit,
      width: width,
      height: height,
    );
  }
}
