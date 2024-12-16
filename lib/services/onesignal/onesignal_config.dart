// import 'dart:io';
// import 'package:onesignal_flutter/onesignal_flutter.dart';

// class OnesignalConfig {
//   static OnesignalConfig? instance;
//   String? token;
//   static OnesignalConfig? getInstance() {
//     if (instance == null) instance = new OnesignalConfig();
//     return instance;
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
//     await OneSignal.shared.setAppId("e82db408-6e3c-4b3a-98f8-6315eddb56d9");

//     await OneSignal.shared.consentGranted(true);

//     await OneSignal.shared.setRequiresUserPrivacyConsent(true);
//     if (Platform.isIOS) {
//       await OneSignal.shared.promptLocationPermission();
//     }
//     await OneSignal.shared
//         .promptUserForPushNotificationPermission(fallbackToSettings: true);

//     // NOTE: Replace with your own app ID from https://www.onesignal.com

//     await OneSignal.shared.requiresUserPrivacyConsent();

//     await getTokenPushNoti();
//     OneSignal.shared.disablePush(false);
//   }

//   Future setUpNoti() async {
//     OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
//       print("PERMISSION STATE CHANGED: ${changes.jsonRepresentation()}");
//     });
//     OneSignal.shared
//         .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
//       // if (result.notification)
//     });

//     OneSignal.shared
//         .setInAppMessageClickedHandler((OSInAppMessageAction action) {});

//     OneSignal.shared
//         .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
//       print("SUBSCRIPTION STATE CHANGED: ${changes.jsonRepresentation()}");
//     });

//     OneSignal.shared.setEmailSubscriptionObserver(
//         (OSEmailSubscriptionStateChanges changes) {
//       print("EMAIL SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
//     });
//   }

//   getTokenPushNoti() async {
//     await OneSignal.shared.getDeviceState().then((deviceState) {
//       token = deviceState!.userId;
//       print("OneSignal: device state: ${deviceState.jsonRepresentation()}");
//     });
//   }
// }
