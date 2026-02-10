// ignore: deprecated_member_use
import 'dart:js' as js;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

class PushService {
  FirebaseMessaging? _messaging;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    // 1. Инициализация Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Web: попытаться зарегистрировать service worker по правильному пути
    if (kIsWeb) {
      try {
        final navigator = js.context['navigator'];
        if (navigator == null || navigator['serviceWorker'] == null) {
          debugPrint('Service workers are not supported in this browser');
        } else {
          await navigator['serviceWorker'].callMethod('register', [
            '/horoscope-app/firebase-messaging-sw.js',
          ]);
          debugPrint(
            'Service worker registered: /horoscope-app/firebase-messaging-sw.js',
          );
        }
      } catch (e) {
        debugPrint('SW register failed on web: $e');
        // Не роняем приложение, просто без web‑push
      }
    }

    // 3. Экземпляр messaging
    _messaging = FirebaseMessaging.instance;

    // 4. Запрос разрешения на уведомления
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // Разрешение не выдали — дальше смысла нет
        return;
      }
    } catch (e) {
      debugPrint('Push permission request failed: $e');
      return;
    }

    // 5. Получаем FCM‑токен
    try {
      String? token;

      if (kIsWeb) {
        // На web не вызываем getToken, чтобы не дергать дефолтный SW Firebase
        debugPrint('Skip getToken on web to avoid default SW registration');
      } else {
        token = await _messaging!.getToken();
      }

      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // 6. Сообщения при активном приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage: ${message.notification?.title}');
    });

    // 7. Клик по пушу из фона
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
      if (navigatorKey != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/today');
      }
    });

    // 8. Открытие приложения пушем из убитого состояния
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
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
    if (_messaging == null) {
      debugPrint('getFcmToken: messaging is null');
      return null;
    }
    try {
      if (kIsWeb) {
        // На web токен сейчас не используем, чтобы не было ошибки default SW
        debugPrint('getFcmToken: skip on web');
        return null;
      }
      return _messaging!.getToken();
    } catch (e) {
      debugPrint('getFcmToken failed: $e');
      return null;
    }
  }
}
