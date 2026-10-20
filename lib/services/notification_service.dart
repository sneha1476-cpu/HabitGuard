import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FirestoreService _firestoreService =
      FirestoreService();

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // --------------------------------------------------
    // 1. Initialize Local Notifications
    // --------------------------------------------------

    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings
        initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // --------------------------------------------------
    // 2. Create Android Notification Channel
    // --------------------------------------------------

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'habitguard_alerts',
      'HabitGuard Alerts',
      description:
          'Notifications related to HabitGuard digital wellbeing.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // --------------------------------------------------
    // 3. Request Android Notification Permission
    // --------------------------------------------------

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // --------------------------------------------------
    // 4. Request Firebase Cloud Messaging Permission
    // --------------------------------------------------

    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'FCM notification permission: '
      '${settings.authorizationStatus}',
    );

    // --------------------------------------------------
    // 5. Get FCM Token
    // --------------------------------------------------

    final String? token =
        await _messaging.getToken();

    debugPrint('FCM TOKEN: $token');

    // Save token to Firestore.
    //
    // This can fail during app startup if the user
    // has not logged in yet. That is okay because
    // LoginScreen also saves the token after login.
    if (token != null && token.isNotEmpty) {
      try {
        await _firestoreService.saveFcmToken(
          token,
        );

        debugPrint(
          'FCM token saved to Firestore successfully.',
        );
      } catch (e) {
        debugPrint(
          'Failed to save FCM token: $e',
        );
      }
    }

    // --------------------------------------------------
    // 6. Listen for FCM Token Refresh
    // --------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        debugPrint(
          'FCM TOKEN REFRESHED: $newToken',
        );

        try {
          await _firestoreService.saveFcmToken(
            newToken,
          );

          debugPrint(
            'New FCM token saved to Firestore.',
          );
        } catch (e) {
          debugPrint(
            'Failed to save refreshed FCM token: $e',
          );
        }
      },
    );

    // --------------------------------------------------
    // 7. Handle FCM Notification in Foreground
    // --------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint(
          'FCM notification received.',
        );

        final RemoteNotification? notification =
            message.notification;

        if (notification != null) {
          debugPrint(
            'Title: ${notification.title}',
          );

          debugPrint(
            'Body: ${notification.body}',
          );

          // Show a local notification when an FCM
          // notification arrives while the app is open.
          await showLocalNotification(
            title:
                notification.title ??
                    'HabitGuard',
            body:
                notification.body ??
                    'HabitGuard notification',
          );
        }
      },
    );
  }

  // --------------------------------------------------
  // Show Local Notification
  // --------------------------------------------------

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      'habitguard_alerts',
      'HabitGuard Alerts',
      channelDescription:
          'Notifications related to HabitGuard digital wellbeing.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails
        notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(100000),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // --------------------------------------------------
  // Show Guardian Alert Locally
  // --------------------------------------------------

  Future<void> showGuardianAlert({
    required String riskLevel,
    required int totalScreenTime,
  }) async {
    await showLocalNotification(
      title: 'HabitGuard Guardian Alert',
      body:
          'HabitGuard detected a sustained '
          '$riskLevel digital-wellbeing risk. '
          'Today\'s screen time is '
          '$totalScreenTime minutes.',
    );
  }
}