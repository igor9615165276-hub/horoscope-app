import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const String _keyUserId = 'user_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveUserId(String id) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserId, id);
  }

  Future<String?> getUserId() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserId);
  }

  Future<bool> hasUserId() async {
    final prefs = await _instance;
    return prefs.containsKey(_keyUserId);
  }

  Future<void> clearUserData() async {
    final prefs = await _instance;
    await prefs.remove(_keyUserId);
  }
}
