import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация SDK Яндекс Mobile Ads
  MobileAds.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horoscope Yandex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TodayScreen(),
    );
  }
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  double _bannerHeight = 0;

  @override
  void initState() {
    super.initState();
    // Загружаем баннер после появления контекста
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanner();
    });
  }

  void _loadBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    const maxHeight = 100;

    final size = BannerAdSize.inline(width: screenWidth, maxHeight: maxHeight);

    _bannerAd = BannerAd(
      adUnitId: 'R-M-18663783-1',
      adSize: size,
      adRequest: const AdRequest(),
      onAdLoaded: () async {
        final calculatedSize = await _bannerAd!.adSize
            .getCalculatedBannerAdSize();
        debugPrint(
          'Yandex banner loaded, size: ${calculatedSize.width}x${calculatedSize.height}',
        );
        setState(() {
          _isBannerLoaded = true;
          _bannerHeight = calculatedSize.height.toDouble();
        });
      },
      onAdFailedToLoad: (error) {
        debugPrint('Yandex banner failed to load: $error');
      },
    );

    _bannerAd!.loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гороскоп + Яндекс баннер')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://horoscope-app-production.up.railway.app/health',
                  );
                  final res = await http.get(uri);
                  debugPrint('Backend status: ${res.statusCode}');
                },
                child: const Text('Проверить backend'),
              ),
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null && _bannerHeight > 0)
            SizedBox(
              width: double.infinity,
              height: _bannerHeight,
              child: AdWidget(bannerAd: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
