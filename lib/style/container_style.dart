import 'package:base_flutter_framework/utils/color.dart';
import 'package:flutter/material.dart';

class ContainerAppStyle {
  BoxDecoration boderInput() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorCommon.colorGreenMain, width: 1));
  }

  BoxDecoration boderGreyInput() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
        border: Border.all(color: ColorCommon.colorBoderInput, width: 1));
  }

  BoxDecoration decorationItemListWhite() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorCommon.colorBorder, width: 1),
        color: ColorCommon.colorWhite);
  }

  BoxDecoration decorationInputListWhite() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ColorCommon.colorBoderInput, width: 1),
        color: ColorCommon.colorWhite);
  }

  BoxDecoration decorationTag() {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorCommon.colorBorder, width: 1),
        color: ColorCommon.colorTag);
  }

  BoxDecoration shadowContainer() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
    );
  }
}
