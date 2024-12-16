import 'package:base_flutter_framework/translations/app_translations.dart';
import 'package:base_flutter_framework/translations/transaction_key.dart';
import 'package:base_flutter_framework/utils/constants/colors.dart';
import 'package:flutter/material.dart';

part 'home_screen.chidren.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      color: AppColor.thirdBackgroundColorLight,
      child: Stack(
        children: [
          Center(
            child:
                Text(AppTranslations.of(context).text(TransactionKey.keyHome)),
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
