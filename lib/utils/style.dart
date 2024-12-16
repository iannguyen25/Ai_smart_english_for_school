import 'package:flutter/material.dart';

class StyleCommon {
  static BoxDecoration decorationRadiusAll(
      {required Color color, required double radius, bool? shadow}) {
    return BoxDecoration(
        boxShadow: shadow == true
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ]
            : null,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        color: color);
  }

  static BoxDecoration decorationRadiusOnly(
      {required BorderRadiusGeometry radius, required Color color}) {
    return BoxDecoration(borderRadius: radius, color: color);
  }

  static TextStyle linkStyle({required double fontSize}) {
    return TextStyle(decoration: TextDecoration.underline, color: Colors.blue);
  }
}
