import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/storage.dart';
import '../../models/horoscope.dart';

class TodayScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Storage storage;

  const TodayScreen({
    super.key,
    required this.apiClient,
    required this.storage,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<List<Horoscope>> _futureHoroscopes;

  @override
  void initState() {
    super.initState();
    _futureHoroscopes = _loadHoroscopes();
  }

  Future<List<Horoscope>> _loadHoroscopes() async {
    final userId = await widget.storage.getUserId();
    if (userId == null) {
      if (!mounted) return [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return [];
    }

    final dynamic response = await widget.apiClient.get(
      '/horoscope/today',
      params: {'user_id': userId, 'lang': 'ru'},
    );

    List<dynamic> items;

    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      if (response['horoscopes'] is List) {
        items = response['horoscopes'] as List;
      } else if (response['data'] is List) {
        items = response['data'] as List;
      } else {
        throw Exception('Неверный формат ответа сервера');
      }
    } else {
      throw Exception('Неверный формат ответа сервера');
    }

    final result = <Horoscope>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        result.add(Horoscope.fromJson(item));
      }
    }
    return result;
  }

  Widget _buildHoroscopeCard(Horoscope h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            h.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(h.text),
        ],
      ),
    );
  }

  Future<void> _openTelegramBot() async {
    final uriApp = Uri.parse('tg://resolve?domain=grokgen_video_bot');
    final uriWeb = Uri.parse('https://t.me/grokgen_video_bot');

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTelegramDev() async {
    final uriApp = Uri.parse('tg://resolve?domain=Rodkin23');
    final uriWeb = Uri.parse('https://t.me/Rodkin23');

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // отключаем стрелку назад
        title: const Text('Гороскоп на сегодня'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              setState(() {
                _futureHoroscopes = _loadHoroscopes();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/horoscope_bg_constellations.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Horoscope>>(
                  future: _futureHoroscopes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Нет данных гороскопа на сегодня'),
                      );
                    } else {
                      final items = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildHoroscopeCard(items[index]);
                        },
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _openTelegramBot,
                        child: const Text(
                          'Воспользуйтесь нашим Telegram ботом для оживления фотографии в видео',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _openTelegramDev,
                        child: const Text(
                          'Создание сайтов, мобильных приложений, чат ботов — пишите в Telegram: @Rodkin23',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
