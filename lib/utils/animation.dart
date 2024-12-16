import 'package:flutter/material.dart';

class AnimationCommon {
  static Widget animationSwitcher({
    required Widget childIntro,
    required Widget childMain,
    required bool intro,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 2),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(child: child, scale: animation);
      },
      child: intro ? childIntro : childMain,
    );
  }

  Widget fadeAnimation(
      {required AnimationController controller,
      required Animation<double> animation,
      required Widget child}) {
    return FadeTransition(opacity: animation, child: child);
  }

  // static Widget animatedPositioned(){
  //   re
  // }
}
