import 'package:flutter/material.dart';

import 'app_registry.dart';

class OSWindow {
  OSWindow({
    required this.app,
    required this.position,
    required this.size,
    required this.z,
    this.argument,
  });
  final AppDefinition app;
  String? argument;
  Offset position;
  Size size;
  int z;
  bool minimized = false;
  bool maximized = false;
}

class WindowManager extends ChangeNotifier {
  WindowManager._();
  static final WindowManager instance = WindowManager._();

  final List<OSWindow> windows = <OSWindow>[];
  int _z = 10;

  int get topZ => _z;

  OSWindow? find(String id) {
    for (final w in windows) {
      if (w.app.id == id) return w;
    }
    return null;
  }

  void open(AppDefinition app, {String? argument}) {
    final existing = find(app.id);
    if (existing != null) {
      existing.minimized = false;
      existing.z = ++_z;
      existing.argument = argument ?? existing.argument;
      notifyListeners();
      return;
    }
    final n = windows.length;
    windows.add(OSWindow(
      app: app,
      position: Offset(40.0 + 28.0 * n, 26.0 + 24.0 * n),
      size: app.size,
      z: ++_z,
      argument: argument,
    ));
    notifyListeners();
  }

  void close(OSWindow w) {
    windows.remove(w);
    notifyListeners();
  }

  void focus(OSWindow w) {
    if (w.z != _z) {
      w.z = ++_z;
      notifyListeners();
    }
  }

  void toggleMinimize(OSWindow w) {
    w.minimized = !w.minimized;
    if (!w.minimized) w.z = ++_z;
    notifyListeners();
  }

  void toggleMaximize(OSWindow w) {
    w.maximized = !w.maximized;
    w.z = ++_z;
    notifyListeners();
  }

  void move(OSWindow w, Offset delta) {
    w.position += delta;
    notifyListeners();
  }

  void resize(OSWindow w, Offset delta) {
    w.size = Size(
      (w.size.width + delta.dx).clamp(320.0, 2000.0),
      (w.size.height + delta.dy).clamp(220.0, 1400.0),
    );
    notifyListeners();
  }
}
