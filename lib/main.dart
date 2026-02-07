import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'package:taskflow_pro/features/splash/presentation/screens/splash_screen.dart';
import 'state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';



// ----------------------------
// BACKGROUND HANDLER
// ----------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("🔥 BG: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin _local =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  // Needed for web
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  }


  runApp(const TaskFlowPro());
}

class TaskFlowPro extends StatefulWidget {
  const TaskFlowPro({super.key});

  @override
  State<TaskFlowPro> createState() => _TaskFlowProState();
}

class _TaskFlowProState extends State<TaskFlowPro> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  // ----------------------------
  // FULL NOTIFICATION SETUP
  // ----------------------------
  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1️⃣ Permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permission: ${settings.authorizationStatus}");

    // 2️⃣ Get token
    String? token = await messaging.getToken();
    print("📱 FCM Token: $token");

    // 3️⃣ Local notification setup
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _local.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      "taskflow_channel",
      "TaskFlow Notifications",
      description: "High importance notifications for TaskFlow Pro",
      importance: Importance.high,
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);

    // 4️⃣ Foreground listener → show notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              "taskflow_channel",
              "TaskFlow Notifications",
              importance: Importance.high,
            ),
          ),
        );
      }

      print("📩 FG: ${notification?.title}");
    });

    // 5️⃣ When app opened by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🚀 Tapped Notification");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: appState.isDark
                ? ThemeMode.dark
                : ThemeMode.light,

            // 🌞 LIGHT THEME
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF4F46E5),
              brightness: Brightness.light,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),

            // 🌙 DARK THEME
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
