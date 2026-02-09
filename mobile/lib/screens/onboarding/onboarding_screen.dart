import 'package:flutter/material.dart';

import '../../services/push_service.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';

class OnboardingScreen extends StatefulWidget {
  final PushService pushService;
  final ApiClient apiClient;
  final Storage storage;

  const OnboardingScreen({
    super.key,
    required this.pushService,
    required this.apiClient,
    required this.storage,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<String> _signKeys = const [
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces',
  ];

  final List<String> _signNamesRu = const [
    'Овен',
    'Телец',
    'Близнецы',
    'Рак',
    'Лев',
    'Дева',
    'Весы',
    'Скорпион',
    'Стрелец',
    'Козерог',
    'Водолей',
    'Рыбы',
  ];

  final Set<String> _selectedSignKeys = {};
  bool _isLoading = false;
  String? _error;

  Future<void> _onContinuePressed() async {
    if (_selectedSignKeys.isEmpty) {
      setState(() {
        _error = 'Выберите хотя бы один знак зодиака';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Пробуем получить FCM‑токен, но не блокируем, если не удалось
      final fcmToken = await widget.pushService.getFcmToken();
      if (fcmToken == null) {
        debugPrint('FCM token is null, продолжаем регистрацию без него');
      }

      final existingUserId = await widget.storage.getUserId();

      final body = {
        'user_id': existingUserId,
        'fcm_token': fcmToken,
        'lang': 'ru',
        'push_time': '09:00',
        'signs': _selectedSignKeys.toList(),
      };

      final response = await widget.apiClient.post(
        '/register_device',
        body: body,
      );

      final userId = response['user_id']?.toString();
      if (userId == null) {
        setState(() {
          _error = 'Сервер не вернул user_id';
        });
        return;
      }

      await widget.storage.saveUserId(userId);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/today');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSignChip(int index) {
    final key = _signKeys[index];
    final nameRu = _signNamesRu[index];
    final isSelected = _selectedSignKeys.contains(key);

    return ChoiceChip(
      label: Text(nameRu),
      selected: isSelected,
      selectedColor: const Color(0xFF7C4DFF).withOpacity(0.25),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSignKeys.add(key);
          } else {
            _selectedSignKeys.remove(key);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = List<Widget>.generate(
      _signKeys.length,
      (index) => _buildSignChip(index),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор знаков')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/horoscope_bg_constellations.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Выберите один или несколько знаков зодиака для ежедневного гороскопа.',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onContinuePressed,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Продолжить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
