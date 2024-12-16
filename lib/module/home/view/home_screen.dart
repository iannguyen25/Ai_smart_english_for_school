// import 'package:base_flutter_framework/translations/app_translations.dart';
// import 'package:base_flutter_framework/translations/transaction_key.dart';
// import 'package:base_flutter_framework/utils/constants/colors.dart';
// import 'package:flutter/material.dart';

// part 'home_screen.chidren.dart';

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     return Container(
//       color: AppColor.thirdBackgroundColorLight,
//       child: Stack(
//         children: [
//           Center(
//             child:
//                 Text(AppTranslations.of(context).text(TransactionKey.keyHome)),
//           ),
//           // Align(
//           //   alignment: Alignment.bottomCenter,
//           //   child: Padding(
//           //     padding: const EdgeInsets.all(25),
//           //     child: Text.rich(
//           //       TextSpan(
//           //         text: '${'version'.tr}: ',
//           //         style: TextAppStyle().versionTextStyle(),
//           //         children: [
//           //           TextSpan(
//           //             text: '1.0.0',
//           //             style: TextAppStyle().versionContentTextStyle(),
//           //           ),
//           //           // can add more TextSpans here...
//           //         ],
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D5B),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 24,),
          onPressed: () {

          },
        ),
        titleSpacing: 0,
        title: const Text(
          'Language Translator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLanguageButton(
                  flag: 'assets/images/us_flag.png',
                  language: 'English',
                ),
                const Icon(Icons.swap_horiz, color: Color(0xFF002D5B), size: 24,),
                _buildLanguageButton(
                  flag: 'assets/images/es_flag.png',
                  language: 'Spanish',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            child: Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 17, bottom: 19, right: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'English',
                                style: TextStyle(
                                  color: Color(0xFF003366),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 24,),
                                onPressed: () {
            
                                },
                              ),
                            ],
                          ),
                          const TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter text here...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Color(0XFFA7A7A7)),
                            ),
                            maxLines: 5,
                          ),
                          Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF002D5B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Translate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.history, 'History'),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF002D5B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'XA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildNavItem(Icons.star_border, 'Favourite'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton({required String flag, required String language}) {
    return Row(
      children: [
        Image.asset(
          flag,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        Text(
          language,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF002D5B)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF002D5B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}