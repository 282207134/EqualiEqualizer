import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class StateStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> data);
}

class LocalStore implements StateStore {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'equali.state.v1';
  @override
  Future<Map<String, dynamic>?> read() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> data) => _preferences.setString(_key, jsonEncode(data));
}
