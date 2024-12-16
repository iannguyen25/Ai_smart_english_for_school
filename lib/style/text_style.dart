import 'package:base_flutter_framework/utils/color.dart';
import 'package:base_flutter_framework/utils/dimens.dart';
import 'package:base_flutter_framework/utils/hex_color.dart';
import 'package:flutter/material.dart';

class TextAppStyle {
  TextStyle inputFormStyle() {
    return TextStyle(
        color: ColorCommon.colorGreenMain,
        fontWeight: FontWeight.w900,
        fontSize: DimensCommon.fontSizeSmallComment);
  }
}
