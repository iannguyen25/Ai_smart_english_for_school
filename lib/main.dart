import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home/home_screen.dart';
import 'services/firebase_initializer.dart';

// Global error handler for catching Firebase type errors
void _handleError(Object error, StackTrace stack) {
  print('Global error handler caught: $error');
  
  // Check for PigeonUserDetail error specifically
  if (error.toString().contains('PigeonUserDetail')) {
    print('Detected PigeonUserDetail type casting error');
    // Log the error but don't crash
  } else {
    // For other errors, you might want to report to a crash reporting service
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }
}

Future<void> main() async {
  // Set custom error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _handleError(details.exception, details.stack ?? StackTrace.current);
  };
  
  // Handle zone errors
  runZonedGuarded(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with proper error handling
    bool isFirebaseInitialized = false;
    try {
      await FirebaseInitializer.initialize();
      isFirebaseInitialized = true;
      
      // Set up Crashlytics only if Firebase is initialized
      if (!kDebugMode && isFirebaseInitialized) {
        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      }
    } catch (e, stackTrace) {
      print("Error initializing Firebase: $e");
      print("Stack trace: $stackTrace");
      
      // Check if this is the PigeonUserDetail error
      if (e.toString().contains('PigeonUserDetail')) {
        print('Detected PigeonUserDetail error during initialization');
        // Try to continue anyway as this error might be non-critical
        isFirebaseInitialized = true;
      }
    }

    // Run the app
    runApp(MyApp(isFirebaseInitialized: isFirebaseInitialized));
  }, _handleError);
}

class MyApp extends StatefulWidget {
  final bool isFirebaseInitialized;
  
  const MyApp({Key? key, this.isFirebaseInitialized = false}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'English Learning App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: !widget.isFirebaseInitialized 
          ? _buildErrorScreen()
          : FutureBuilder<bool>(
              future: _checkUserLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }
                
                if (snapshot.hasError) {
                  print("Error checking login state: ${snapshot.error}");
                  
                  // Check if this is a PigeonUserDetail error
                  if (snapshot.error.toString().contains('PigeonUserDetail')) {
                    print('PigeonUserDetail error during login check - proceeding to login screen');
                  }
                  
                  // If there's an error checking login, go to login screen
                  return LoginScreen();
                }
                
                final bool isLoggedIn = snapshot.data ?? false;
                return isLoggedIn ? HomeScreen() : LoginScreen();
              },
            ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to initialize app',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'There was a problem starting the app. Please try again later.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Restart the app or retry initialization
                FirebaseInitializer.initialize().then((_) {
                  setState(() {});
                }).catchError((error) {
                  print('Error during retry: $error');
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUserLoggedIn() async {
    try {
      return _authService.currentUser != null;
    } catch (e) {
      print("Error in _checkUserLoggedIn: $e");
      return false;
    }
  }
}
