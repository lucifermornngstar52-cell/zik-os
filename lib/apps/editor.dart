import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/fs_service.dart';

class EditorApp extends StatefulWidget {
  const EditorApp({super.key, this.path});
  final String? path;

  @override
  State<EditorApp> createState() => _EditorAppState();
}

class _EditorAppState extends State<EditorApp> {
  late final HighlightedController _controller;
  WebViewController? _web;
  String? _path;
  String _lang = 'txt';
  bool _dirty = false;
  bool _preview = false;

  static String _detectLang(String? path) {
    final ext = (path ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'html':
        return 'html';
      case 'js':
        return 'js';
      case 'css':
        return 'css';
      case 'py':
        return 'py';
      case 'dart':
        return 'dart';
      case 'json':
        return 'json';
      default:
        return 'txt';
    }
  }

  @override
  void initState() {
    super.initState();
    _path = widget.path;
    _lang = _detectLang(_path);
    String initial = '';
    if (_path != null && FS.exists(_path!)) {
      try {
        initial = FS.read(_path!);
      } catch (_) {}
    }
    _controller = HighlightedController(text: initial, lang: _lang);
    _controller.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _askName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Имя файла (в projects/)'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'index.html'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Сохранить')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    var path = _path;
    if (path == null) {
      final name = await _askName();
      if (name == null || name.trim().isEmpty) return;
      path = 'projects/${name.trim()}';
    }
    try {
      FS.write(path, _controller.text);
      if (!mounted) return;
      setState(() {
        _path = path;
        _dirty = false;
        _lang = _detectLang(path);
        _controller.lang = _lang;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сохранено: $path'), duration: const Duration(seconds: 1)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  void _togglePreview() {
    final isHtml = _lang == 'html' || (_path ?? '').endsWith('.html');
    if (!isHtml) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Превью доступно для HTML-файлов')));
      return;
    }
    _web ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    setState(() => _preview = !_preview);
    if (_preview) {
      _web!.loadHtmlString(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_path ?? 'Без имени'}${_dirty ? ' *' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: scheme.onSurfaceVariant),
                ),
              ),
              DropdownButton<String>(
                value: _lang,
                underline: const SizedBox.shrink(),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'html', child: Text('HTML')),
                  DropdownMenuItem<String>(value: 'js', child: Text('JS')),
                  DropdownMenuItem<String>(value: 'css', child: Text('CSS')),
                  DropdownMenuItem<String>(value: 'py', child: Text('Python')),
                  DropdownMenuItem<String>(value: 'dart', child: Text('Dart')),
                  DropdownMenuItem<String>(value: 'json', child: Text('JSON')),
                  DropdownMenuItem<String>(value: 'txt', child: Text('Текст')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _lang = v;
                      _controller.lang = v;
                    });
                  }
                },
              ),
              IconButton(
                tooltip: 'Превью',
                icon: Icon(_preview ? Icons.edit : Icons.play_arrow),
                onPressed: _togglePreview,
              ),
              IconButton(
                tooltip: 'Сохранить',
                icon: const Icon(Icons.save_outlined),
                onPressed: _save,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: _preview && _web != null
              ? WebViewWidget(controller: _web!)
              : TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
        ),
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: scheme.surface,
          alignment: Alignment.centerLeft,
          child: Text(
            '${_lang.toUpperCase()} · ${_controller.text.split('\n').length} строк${_dirty ? ' · не сохранено' : ''}',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class HighlightedController extends TextEditingController {
  HighlightedController({required String text, required this.lang}) {
    this.text = text;
  }
  String lang;

  static const Map<String, List<String>> _keywords = <String, List<String>>{
    'js': <String>[
      'const', 'let', 'var', 'function', 'return', 'if', 'else', 'for', 'while',
      'class', 'new', 'await', 'async', 'import', 'export', 'true', 'false',
      'null', 'this', 'typeof', 'of', 'in'
    ],
    'py': <String>[
      'def', 'return', 'if', 'elif', 'else', 'for', 'while', 'class', 'import',
      'from', 'True', 'False', 'None', 'lambda', 'try', 'except', 'with', 'as',
      'in', 'not', 'and', 'or', 'print', 'range'
    ],
    'dart': <String>[
      'void', 'var', 'final', 'const', 'class', 'return', 'if', 'else', 'for',
      'while', 'new', 'import', 'this', 'true', 'false', 'null', 'static',
      'await', 'async', 'super', 'extends', 'implements'
    ],
    'css': <String>[
      'color', 'background', 'margin', 'padding', 'border', 'font', 'display',
      'width', 'height', 'position', 'top', 'left', 'right', 'bottom', 'flex'
    ],
  };

  static String _commentPattern(String lang) {
    switch (lang) {
      case 'js':
      case 'dart':
      case 'json':
        return r'//[^\n]*|/\*[\s\S]*?\*/';
      case 'py':
        return r'#[^\n]*';
      case 'css':
        return r'/\*[\s\S]*?\*/';
      case 'html':
        return r'<!--[\s\S]*?-->';
      default:
        return '';
    }
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context, TextStyle? style, required bool withComposing}) {
    final text = this.text;
    final base = style ?? const TextStyle(fontFamily: 'monospace', fontSize: 14);
    if (text.isEmpty) return TextSpan(style: base, text: '');

    final commentP = _commentPattern(lang);
    final kw = _keywords[lang] ?? <String>[];
    final kwP = kw.isEmpty ? '' : '|\\b(?:${kw.join('|')})\\b';
    final pattern = RegExp(
      (commentP.isEmpty ? '' : '($commentP)|') +
          r'("(?:[^"\\\n]|\\.)*")' +
          r"|('(?:[^'\\\n]|\\.)*')" +
          r'|\b(\d+(?:\.\d+)?)\b' +
          kwP,
    );

    final spans = <TextSpan>[];
    var pos = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, m.start)));
      }
      final t = m.group(0)!;
      Color color;
      if (t.startsWith('//') ||
          t.startsWith('#') ||
          t.startsWith('/*') ||
          t.startsWith('<!--')) {
        color = const Color(0xFF6A9955);
      } else if (t.startsWith('"') || t.startsWith("'")) {
        color = const Color(0xFFCE9178);
      } else if (RegExp(r'^\d').hasMatch(t)) {
        color = const Color(0xFFB5CEA8);
      } else {
        color = const Color(0xFF569CD6);
      }
      spans.add(TextSpan(text: t, style: TextStyle(color: color)));
      pos = m.end;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: base, children: spans);
  }
}
