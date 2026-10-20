import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart' show bootAt;
import '../core/fs_service.dart';
import '../shell/app_registry.dart';
import '../shell/window_manager.dart';

class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  final List<String> _lines = <String>[];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _cwd = '';

  @override
  void initState() {
    super.initState();
    _lines.add('ZikOS Terminal 1.0.0 — введите help для списка команд.');
    _lines.add('');
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _out(String line) => _lines.add(line);

  String _abs(String p) {
    if (p.startsWith('/home')) return FS.normalize(p.replaceFirst('/home', ''));
    if (p.startsWith('~')) return FS.normalize(p.substring(1));
    if (p.startsWith('/')) return FS.normalize(p);
    if (_cwd.isEmpty) return FS.normalize(p);
    return FS.normalize('$_cwd/$p');
  }

  void _tree(String dir, int depth, int maxDepth) {
    for (final e in FS.list(dir)) {
      _out('${'  ' * depth}${FS.entityName(e)}${e is Directory ? '/' : ''}');
      if (e is Directory && depth < maxDepth) {
        _tree(FS.relPathOf(e), depth + 1, maxDepth);
      }
    }
  }

  void _exec(String cmd) {
    final parts = cmd.split(RegExp(r'\s+'));
    final name = parts[0];
    final args = parts.sublist(1);
    switch (name) {
      case 'help':
        _out('Доступные команды:');
        _out('  ls, cd, pwd, cat, mkdir, touch, rm, tree   — файлы');
        _out('  echo, clear, date, whoami, uname, neofetch, uptime');
        _out('  open <files|terminal|code|converter|settings>');
        break;
      case 'ls':
        final target = args.isEmpty ? _cwd : _abs(args[0]);
        if (!FS.isDir(target)) {
          _out('ls: не найдено: ${args.isEmpty ? '.' : args[0]}');
          break;
        }
        final items = FS.list(target);
        if (items.isEmpty) {
          _out('(пусто)');
          break;
        }
        for (final e in items) {
          final n = FS.entityName(e);
          _out(e is Directory ? '$n/' : n);
        }
        break;
      case 'cd':
        if (args.isEmpty) {
          _cwd = '';
          break;
        }
        final t = _abs(args[0]);
        if (t.isEmpty || FS.isDir(t)) {
          _cwd = t;
        } else {
          _out('cd: папка не найдена: ${args[0]}');
        }
        break;
      case 'pwd':
        _out('/home${_cwd.isEmpty ? '' : '/$_cwd'}');
        break;
      case 'cat':
        if (args.isEmpty) {
          _out('cat: укажите файл');
          break;
        }
        final t = _abs(args[0]);
        if (!FS.exists(t)) {
          _out('cat: файл не найден: ${args[0]}');
          break;
        }
        try {
          _out(FS.read(t));
        } catch (e) {
          _out('cat: не удалось прочитать файл');
        }
        break;
      case 'echo':
        _out(args.join(' '));
        break;
      case 'mkdir':
        if (args.isEmpty) {
          _out('mkdir: укажите имя папки');
          break;
        }
        try {
          FS.mkdir(_abs(args[0]));
        } catch (e) {
          _out('mkdir: ошибка');
        }
        break;
      case 'touch':
        if (args.isEmpty) {
          _out('touch: укажите имя файла');
          break;
        }
        try {
          if (!FS.exists(_abs(args[0]))) FS.write(_abs(args[0]), '');
        } catch (e) {
          _out('touch: ошибка');
        }
        break;
      case 'rm':
        if (args.isNotEmpty && args[0] == '-r') args.removeAt(0);
        if (args.isEmpty) {
          _out('rm: укажите путь');
          break;
        }
        final t = _abs(args[0]);
        if (t.isEmpty) {
          _out('rm: нельзя удалить /home');
          break;
        }
        try {
          FS.delete(t);
        } catch (e) {
          _out('rm: ошибка');
        }
        break;
      case 'tree':
        _tree(_cwd, 0, 2);
        break;
      case 'clear':
        _lines.clear();
        break;
      case 'date':
        _out(DateTime.now().toString());
        break;
      case 'whoami':
        _out('zik');
        break;
      case 'uname':
        _out('ZikOS 1.0.0 zikos-kernel android-aarch64');
        break;
      case 'uptime':
        final up = DateTime.now().difference(bootAt);
        _out('up ${up.inMinutes} мин ${up.inSeconds % 60} сек');
        break;
      case 'neofetch':
        _lines.addAll(<String>[
          '     ______________        zik@zikos',
          '    / _  | ____| _ \\       -----------------------',
          '   / / _ \\ \\_ \\ / _ \\      OS: ZikOS 1.0.0 (Android)',
          '  / / |\\ \\__| |\\ \\ \\       Kernel: zikos-kernel 1.0.0',
          ' / /_|| |___)||_|| \\      Shell: ziksh 1.0',
          ' \\____/\\___/\\___\\__/      Device: ZIK W1027',
          '                           Memory: 4096 MiB',
        ]);
        break;
      case 'open':
        if (args.isEmpty) {
          _out('open: укажите: files, terminal, code, converter, settings');
          break;
        }
        AppDefinition? found;
        for (final app in Apps.all) {
          if (app.id == args[0]) found = app;
        }
        if (found != null) {
          WindowManager.instance.open(found);
          _out('Запуск: ${found.title}');
        } else {
          _out('open: приложение не найдено: ${args[0]}');
        }
        break;
      default:
        _out('zsh: команда не найдена: $name (введите help)');
    }
  }

  void _run() {
    final raw = _input.text;
    final cmd = raw.trim();
    _out('zik@zikos:${_cwd.isEmpty ? '~' : _cwd}\$ $cmd');
    if (cmd.isNotEmpty) {
      try {
        _exec(cmd);
      } catch (e) {
        _out('ошибка: $e');
      }
    }
    _input.clear();
    setState(() {});
    _scrollBottom();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = 'zik@zikos:${_cwd.isEmpty ? '~' : _cwd}\$';
    return Container(
      color: const Color(0xFF0A0E14),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(10),
              children: <Widget>[
                for (final l in _lines)
                  Text(
                    l,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFFC7E8D0)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF11161D),
            child: Row(
              children: <Widget>[
                Text('$prompt ',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFF7DE3A3))),
                Expanded(
                  child: TextField(
                    controller: _input,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFE6EDF3)),
                    decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: ''),
                    onSubmitted: (_) => _run(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
