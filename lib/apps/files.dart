import 'dart:io';

import 'package:flutter/material.dart';

import '../core/fs_service.dart';
import '../shell/app_registry.dart';
import '../shell/window_manager.dart';

class FilesApp extends StatefulWidget {
  const FilesApp({super.key});

  @override
  State<FilesApp> createState() => _FilesAppState();
}

class _FilesAppState extends State<FilesApp> {
  String _cwd = '';

  void _refresh() => setState(() {});

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _openEntity(FileSystemEntity e) {
    if (e is Directory) {
      setState(() => _cwd = FS.relPathOf(e));
    } else {
      final rel = FS.relPathOf(e);
      final ext = rel.contains('.') ? rel.split('.').last.toLowerCase() : '';
      const textExts = <String>[
        'txt', 'md', 'html', 'js', 'css', 'py', 'json', 'dart', 'xml', 'yml', 'yaml', 'log', 'sh'
      ];
      if (textExts.contains(ext)) {
        WindowManager.instance.open(Apps.code, argument: rel);
      } else {
        _toast('Нет приложения для .$ext — открой в «Код» через меню (удержание)');
      }
    }
  }

  Future<String?> _askText(String title, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('ОК')),
        ],
      ),
    );
  }

  Future<void> _menu(FileSystemEntity e) async {
    final rel = FS.relPathOf(e);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Переименовать'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Открыть в редакторе кода'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'rename':
        final name = await _askText('Переименовать', FS.entityName(e));
        if (name != null && name.trim().isNotEmpty) {
          try {
            FS.rename(rel, _cwd.isEmpty ? name.trim() : '$_cwd/${name.trim()}');
            _refresh();
          } catch (err) {
            _toast('Не удалось переименовать');
          }
        }
        break;
      case 'open':
        WindowManager.instance.open(Apps.code, argument: rel);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удалить?'),
            content: Text(FS.entityName(e)),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Удалить')),
            ],
          ),
        );
        if (ok == true) {
          try {
            FS.delete(rel);
            _refresh();
          } catch (err) {
            _toast('Не удалось удалить');
          }
        }
        break;
    }
  }

  Future<void> _create(bool folder) async {
    final name = await _askText(folder ? 'Новая папка' : 'Новый файл', '');
    if (name == null || name.trim().isEmpty) return;
    final rel = _cwd.isEmpty ? name.trim() : '$_cwd/${name.trim()}';
    try {
      if (folder) {
        FS.mkdir(rel);
      } else {
        FS.write(rel, '');
      }
      _refresh();
    } catch (e) {
      _toast('Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = FS.list(_cwd);
    final crumbs = _cwd.isEmpty ? <String>[] : _cwd.split('/');
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Вверх',
                icon: const Icon(Icons.arrow_upward),
                onPressed: _cwd.isEmpty
                    ? null
                    : () => setState(() {
                          final parts = _cwd.split('/')..removeLast();
                          _cwd = parts.join('/');
                        }),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => setState(() => _cwd = ''),
                        child: const Text('/home'),
                      ),
                      for (int i = 0; i < crumbs.length; i++)
                        TextButton(
                          onPressed: () =>
                              setState(() => _cwd = crumbs.sublist(0, i + 1).join('/')),
                          child: Text('/${crumbs[i]}'),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                  tooltip: 'Новая папка',
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: () => _create(true)),
              IconButton(
                  tooltip: 'Новый файл',
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: () => _create(false)),
              IconButton(
                  tooltip: 'Обновить',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text('Папка пуста',
                      style: TextStyle(color: scheme.onSurfaceVariant)))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130, childAspectRatio: 0.95),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _EntryTile(
                    entity: entries[i],
                    onTap: () => _openEntity(entries[i]),
                    onLongPress: () => _menu(entries[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(
      {required this.entity, required this.onTap, required this.onLongPress});
  final FileSystemEntity entity;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDir = entity is Directory;
    final name = entity.path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    IconData icon = Icons.description_outlined;
    Color color = scheme.primary;
    if (isDir) {
      icon = Icons.folder_rounded;
      color = const Color(0xFFF6B73C);
    } else if (<String>['html', 'js', 'css'].contains(ext)) {
      icon = Icons.html;
      color = const Color(0xFF61DAFB);
    } else if (ext == 'py') {
      icon = Icons.terminal;
      color = const Color(0xFF4B8BBE);
    } else if (ext == 'json') {
      icon = Icons.data_object;
      color = const Color(0xFFCB9C2B);
    }
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
