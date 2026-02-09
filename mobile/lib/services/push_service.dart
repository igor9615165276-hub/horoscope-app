import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

class PushService {
  late final FirebaseMessaging _messaging;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    // 1. Инициализируем Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Берём instance только после initializeApp
    _messaging = FirebaseMessaging.instance;

    // 3. Запрашиваем разрешения на уведомления (не роняем при ошибке)
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Push permission request failed: $e');
    }

    // 4. Получаем и логируем FCM-токен, но оборачиваем в try/catch
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // 5. Пуши, когда приложение на экране
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage: ${message.notification?.title}');
    });

    // 6. Клик по пушу, когда приложение было в фоне
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
      if (navigatorKey != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/today');
      }
    });

    // 7. Приложение открыто пушем из "убитого" состояния
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint('getInitialMessage: ${initialMessage.data}');
        if (navigatorKey != null && navigatorKey.currentState != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState!.pushNamed('/today');
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to get initial FCM message: $e');
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return _messaging.getToken();
    } catch (e) {
      debugPrint('getFcmToken failed: $e');
      return null;
    }
  }
}
