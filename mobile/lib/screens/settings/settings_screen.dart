import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/storage.dart';
import '../../models/user_settings.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Storage storage;

  const SettingsScreen({
    super.key,
    required this.apiClient,
    required this.storage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  String? _userId;
  TimeOfDay _pushTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isActive = true;

  // Технические коды знаков (для бэкенда) — такие же, как в онбординге
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

  // Русские названия для UI
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storedUserId = await widget.storage.getUserId();
      if (storedUserId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      _userId = storedUserId;

      final resp = await widget.apiClient.get(
        '/user/settings',
        params: {'user_id': storedUserId},
      );

      final settings = UserSettings.fromJson(resp as Map<String, dynamic>);

      final parts = settings.pushTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      _selectedSignKeys
        ..clear()
        ..addAll(settings.signs);

      setState(() {
        _pushTime = TimeOfDay(hour: hour, minute: minute);
        _isActive = settings.isActive;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки настроек: $e')));
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pushTime,
    );
    if (picked != null) {
      setState(() {
        _pushTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала нужно зарегистрировать устройство'),
        ),
      );
      return;
    }

    if (_selectedSignKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один знак зодиака')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final pushTimeStr =
          '${_pushTime.hour.toString().padLeft(2, '0')}:${_pushTime.minute.toString().padLeft(2, '0')}';

      final body = {
        'user_id': _userId,
        'signs': _selectedSignKeys.toList(),
        'push_time': pushTimeStr,
        'is_active': _isActive,
      };

      final resp = await widget.apiClient.put('/user/settings', body: body);

      final settings = UserSettings.fromJson(resp as Map<String, dynamic>);

      final parts = settings.pushTime.split(':');
      final hour = int.tryParse(parts[0]) ?? _pushTime.hour;
      final minute = int.tryParse(parts[1]) ?? _pushTime.minute;

      _selectedSignKeys
        ..clear()
        ..addAll(settings.signs);

      setState(() {
        _pushTime = TimeOfDay(hour: hour, minute: minute);
        _isActive = settings.isActive;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildSignChip(int index) {
    final key = _signKeys[index];
    final nameRu = _signNamesRu[index];
    final isSelected = _selectedSignKeys.contains(key);

    return ChoiceChip(
      label: Text(nameRu, style: const TextStyle(color: Colors.white)),
      selected: isSelected,
      selectedColor: Colors.white24,
      backgroundColor: Colors.black45,
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
    final timeStr =
        '${_pushTime.hour.toString().padLeft(2, '0')}:${_pushTime.minute.toString().padLeft(2, '0')}';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chips = List<Widget>.generate(
      _signKeys.length,
      (index) => _buildSignChip(index),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
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
                  'Выберите знаки, время и включите/выключите уведомления.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Wrap(spacing: 8, runSpacing: 8, children: chips),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          title: const Text(
                            'Уведомления',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _isActive,
                          activeColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text(
                            'Время пушей',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '$timeStr (по Москве)',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveSettings,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
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
