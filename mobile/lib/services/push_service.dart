import 'dart:js' as js;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

class PushService {
  late final FirebaseMessaging _messaging;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    // 1. Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Для web — сначала регистрируем service worker с правильным путём
    if (kIsWeb) {
      try {
        await js.context.callMethod('navigator.serviceWorker.register', [
          '/horoscope-app/firebase-messaging-sw.js',
        ]);
        debugPrint(
          'Service worker registered: /horoscope-app/firebase-messaging-sw.js',
        );
      } catch (e) {
        debugPrint('SW register failed on web: $e');
        // Если SW не зарегистрировался — дальше смысла в web‑pushах нет
        return;
      }
    }

    // 3. Берём instance после initializeApp
    _messaging = FirebaseMessaging.instance;

    // 4. Разрешения на уведомления
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // Нет разрешения — выходим, но не валим приложение
        return;
      }
    } catch (e) {
      debugPrint('Push permission request failed: $e');
      // на web/iOS/Android просто не будет токена
      return;
    }

    // 5. Получаем и логируем FCM‑токен
    try {
      final token = await _messaging.getToken(
        // если используешь VAPID‑ключ для web — добавь сюда:
        // vapidKey: 'ТВОЙ_VAPID_KEY',
      );
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // 6. onMessage (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage: ${message.notification?.title}');
    });

    // 7. onMessageOpenedApp (из фона)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
      if (navigatorKey != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/today');
      }
    });

    // 8. getInitialMessage (из убитого состояния)
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
