import 'package:flutter/material.dart';

import 'services/push_service.dart';
import 'core/api_client.dart';
import 'core/storage.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/today/today_screen.dart';
import 'screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pushService = PushService();
  try {
    await pushService.init(navigatorKey: navigatorKey);
  } catch (e) {
    debugPrint('PushService init failed: $e');
  }

  final apiClient = ApiClient(
    baseUrl: 'https://horoscope-app-production.up.railway.app',
  );

  final storage = Storage();
  final hasUser = await storage.hasUserId();

  runApp(
    MyApp(
      pushService: pushService,
      apiClient: apiClient,
      storage: storage,
      startRoute: hasUser ? '/today' : '/',
    ),
  );
}

class MyApp extends StatelessWidget {
  final PushService pushService;
  final ApiClient apiClient;
  final Storage storage;
  final String startRoute;

  const MyApp({
    super.key,
    required this.pushService,
    required this.apiClient,
    required this.storage,
    required this.startRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horoscope today', // новое имя внутри Flutter
      navigatorKey: navigatorKey,
      routes: {
        '/': (_) => OnboardingScreen(
          pushService: pushService,
          apiClient: apiClient,
          storage: storage,
        ),
        '/today': (_) => TodayScreen(apiClient: apiClient, storage: storage),
        '/settings': (_) =>
            SettingsScreen(apiClient: apiClient, storage: storage),
      },
      initialRoute: startRoute,
    );
  }
}
