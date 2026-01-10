import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:respyr_clinical/authentication/screens/login_screen.dart';
import 'package:respyr_clinical/authentication/sign_in/presentation/screens/sign_in.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/device_connectivity/data/usb_repository_impl.dart';
import 'package:respyr_clinical/device_connectivity/presentation/cubit/usb_connection_cubit.dart';
import 'package:respyr_clinical/router/app_pages.dart';
import 'package:respyr_clinical/router/app_routers.dart';
import 'package:upgrader/upgrader.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'authentication/corporate/corporate_login/presentation/screens/corporate_login.dart';
import 'splash/splash.dart';
import 'authentication/services/clinical_name_getx_controller.dart';
import 'log_manager/device_info.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background handler for Firebase push messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('🔔 Background message received: ${message.messageId}');
  }
}

/// Sends uncaught errors and crash logs to server
Future<void> sendErrorToServer(String error, String stack) async {
  const url = 'https://humorstech.com/log_manager/app_error_report.php';
  final deviceDetails = await getDeviceDetails();

  final body = {'error': error, 'stack': stack, ...deviceDetails};

  try {
    final response = await http.post(Uri.parse(url), body: body);
    if (kDebugMode) {
      print('✅ Error report sent. Server response: ${response.body}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to send error to server: $e');
    }
  }
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp();
      await GetStorage.init();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize local notifications
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: android, iOS: ios);
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      // UI error widget override
      // ErrorWidget.builder = (FlutterErrorDetails details) {
      //   sendErrorToServer(
      //     details.exceptionAsString(),
      //     details.stack.toString(),
      //   );
      //   return Material(
      //     child: Center(
      //       child: Text(
      //         'Something went wrong.\nPlease restart the app.',
      //         textAlign: TextAlign.center,
      //         style: TextStyle(fontSize: 18, color: Colors.blue),
      //       ),
      //     ),
      //   );
      // };

      // Global Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        sendErrorToServer(
          details.exceptionAsString(),
          details.stack.toString(),
        );
      };
      final usbService = ClinicalUsbCommunicationServices();
      final usbRepository = UsbRepositoryImpl(usbService);
      // Run the app
      runApp(
        MultiBlocProvider(
          providers: [BlocProvider(create: (_) => UsbCubit(usbRepository))],
          child: const MyApp(),
        ),
      );

      // Optional: enable wakelock
      WakelockPlus.enable();
    },
    (error, stackTrace) {
      sendErrorToServer(error.toString(), stackTrace.toString());
    },
  );
}

class ProfileCubit {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print('🔓 Notification tapped: ${message.notification?.title}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Get.put(ClinicalController());
    _setupFCM();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
