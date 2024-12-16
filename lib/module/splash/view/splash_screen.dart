import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -250,
            left: -151,
            child: Container(
              width: 446,
              height: 410,
              decoration: BoxDecoration(
                color: const Color(0xFF007AF5).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -248,
            left: 157,
            child: Container(
              width: 446,
              height: 410,
              decoration: BoxDecoration(
                color: const Color(0xFFF28739).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Logo and text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 318,),
                Center(
                  child: SizedBox(
                    width: 99,
                    height: 82,
                    child: Image.asset(
                      'assets/images/translate_logo.png',
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'TRANSLATE ON THE GO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 207),
                // Loading dots
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Image.asset(
                      'assets/images/loading.png',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}