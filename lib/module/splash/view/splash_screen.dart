import 'package:base_flutter_framework/components/widget/image_widget/fcore_image.dart';
import 'package:base_flutter_framework/resource/resource_icon.dart';
import 'package:base_flutter_framework/resource/resource_image.dart';
import 'package:base_flutter_framework/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      color: AppColor.thirdBackgroundColorLight,
      child: Stack(
        children: [
          Center(
            child: FCoreImage(
              ResourceIcon.iconApp,
              width: width * 0.36,
              fit: BoxFit.fitWidth,
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Padding(
          //     padding: const EdgeInsets.all(25),
          //     child: Text.rich(
          //       TextSpan(
          //         text: '${'version'.tr}: ',
          //         style: TextAppStyle().versionTextStyle(),
          //         children: [
          //           TextSpan(
          //             text: '1.0.0',
          //             style: TextAppStyle().versionContentTextStyle(),
          //           ),
          //           // can add more TextSpans here...
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
