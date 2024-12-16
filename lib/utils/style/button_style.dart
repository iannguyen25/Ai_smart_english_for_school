import 'package:flutter/material.dart';

class ButtonAppStyle {
  ButtonStyle buttonWrap() {
    return TextButton.styleFrom(
      
      padding: EdgeInsets.all(0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap);
  }
}
