import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._(this._prefs);
  final SharedPreferences _prefs;

  static late final Settings instance;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    instance = Settings._(prefs);
  }

  static const List<Color> accents = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  static const List<List<Color>> wallpapers = <List<Color>>[
    <Color>[Color(0xFF0B1220), Color(0xFF1E293B), Color(0xFF312E81)],
    <Color>[Color(0xFF020617), Color(0xFF064E3B), Color(0xFF0F766E)],
    <Color>[Color(0xFF1C1917), Color(0xFF7C2D12), Color(0xFFBE123C)],
    <Color>[Color(0xFF020617), Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
  ];

  int get accentIndex => _prefs.getInt('accent') ?? 0;
  set accentIndex(int v) {
    _prefs.setInt('accent', v);
    notifyListeners();
  }

  int get wallpaperIndex => _prefs.getInt('wallpaper') ?? 0;
  set wallpaperIndex(int v) {
    _prefs.setInt('wallpaper', v);
    notifyListeners();
  }

  bool get dark => _prefs.getBool('dark') ?? true;
  set dark(bool v) {
    _prefs.setBool('dark', v);
    notifyListeners();
  }

  Brightness get brightness => dark ? Brightness.dark : Brightness.light;
  Color get accent => accents[accentIndex.clamp(0, accents.length - 1)];
}
