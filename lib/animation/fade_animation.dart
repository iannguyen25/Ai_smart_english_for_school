import 'package:flutter/material.dart';

Widget fadeAnimation(
    {required AnimationController controller,
    required Animation<double> animation,
    required Widget child}) {
  return FadeTransition(opacity: animation, child: child);
}
