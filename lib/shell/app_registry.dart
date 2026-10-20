import 'package:flutter/material.dart';

import '../apps/converter.dart';
import '../apps/editor.dart';
import '../apps/files.dart';
import '../apps/settings_app.dart';
import '../apps/terminal.dart';

class AppDefinition {
  const AppDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.size,
    required this.builder,
  });
  final String id;
  final String title;
  final IconData icon;
  final Size size;
  final Widget Function(String? argument) builder;
}

Widget _filesBuilder(String? a) => const FilesApp();
Widget _terminalBuilder(String? a) => const TerminalApp();
Widget _codeBuilder(String? a) => EditorApp(path: a);
Widget _converterBuilder(String? a) => const ConverterApp();
Widget _settingsBuilder(String? a) => const SettingsApp();

class Apps {
  static const AppDefinition files = AppDefinition(
      id: 'files',
      title: 'Файлы',
      icon: Icons.folder_open_rounded,
      size: Size(780, 540),
      builder: _filesBuilder);
  static const AppDefinition terminal = AppDefinition(
      id: 'terminal',
      title: 'Терминал',
      icon: Icons.terminal_rounded,
      size: Size(680, 440),
      builder: _terminalBuilder);
  static const AppDefinition code = AppDefinition(
      id: 'code',
      title: 'Код',
      icon: Icons.code_rounded,
      size: Size(820, 580),
      builder: _codeBuilder);
  static const AppDefinition converter = AppDefinition(
      id: 'converter',
      title: 'Конвертер',
      icon: Icons.swap_horiz_rounded,
      size: Size(540, 500),
      builder: _converterBuilder);
  static const AppDefinition settings = AppDefinition(
      id: 'settings',
      title: 'Настройки',
      icon: Icons.tune_rounded,
      size: Size(560, 540),
      builder: _settingsBuilder);
  static const List<AppDefinition> all = <AppDefinition>[
    files,
    terminal,
    code,
    converter,
    settings,
  ];
}
