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

  TextStyle textGreyBoldStyle() {
    return TextStyle(
        color: ColorCommon.colorTextGrey,
        fontWeight: FontWeight.w900,
        fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle textGreyStyle() {
    return TextStyle(
        color: ColorCommon.colorTextGrey,
        fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle textRedStyle() {
    return TextStyle(color: Colors.red, fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle textToolBar() {
    return TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: DimensCommon.fontSizeBig);
  }

  TextStyle textBlackBoldStyle() {
    return TextStyle(
        color: ColorCommon.colorBlack,
        fontWeight: FontWeight.w900,
        fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle textBlackBoldBigStyle() {
    return TextStyle(
        color: ColorCommon.colorBlack,
        fontWeight: FontWeight.w900,
        fontSize: DimensCommon.fontSizeBig);
  }

  TextStyle styleHintText() {
    return TextStyle(
        color: ColorCommon.colorHintText,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle styleTitle() {
    return TextStyle(
      color: ColorCommon.colorBlack,
      fontWeight: FontWeight.w700,
      fontSize: DimensCommon.fontMediumBig,
    );
  }

  TextStyle styleTitleBig() {
    return TextStyle(
      color: ColorCommon.colorTitleBig,
      fontWeight: FontWeight.w700,
      fontSize: DimensCommon.fontSizeBig,
    );
  }

  TextStyle textBlackStyle() {
    return TextStyle(
        color: ColorCommon.colorBlack, fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle textGreenBoldStyle() {
    return TextStyle(
        fontWeight: FontWeight.w700,
        color: ColorCommon.colorCostArea,
        fontSize: DimensCommon.fontSizeMedium);
  }

  TextStyle styleContent() {
    return TextStyle(
      color: ColorCommon.colorBlack,
      fontWeight: FontWeight.w400,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }

  TextStyle styleTextTag() {
    return TextStyle(
      color: ColorCommon.colorBlack,
      fontWeight: FontWeight.w600,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }

  TextStyle textHint() {
    return TextStyle(
        color: ColorCommon.colorHintText,
        fontSize: DimensCommon.fontSizeSmallComment,
        fontStyle: FontStyle.italic);
  }

  TextStyle styleCostArea() {
    return TextStyle(
      color: ColorCommon.colorCostArea,
      fontWeight: FontWeight.w700,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }

  TextStyle styleDateGreen() {
    return TextStyle(
      color: ColorCommon.colorCostArea,
      fontWeight: FontWeight.w400,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }

  TextStyle styleDateBlack() {
    return TextStyle(
      color: ColorCommon.colorBlack2,
      fontWeight: FontWeight.w400,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }

  TextStyle styleFullSelect() {
    return TextStyle(
      color: ColorCommon.colorFullSelect,
      fontWeight: FontWeight.w600,
      fontSize: DimensCommon.fontSizeMedium,
    );
  }
}
