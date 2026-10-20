import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_registry.dart';

class StartMenu extends StatefulWidget {
  const StartMenu({super.key, required this.onOpen});
  final void Function(AppDefinition app) onOpen;

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apps = Apps.all
        .where((a) => a.title.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Поиск приложений',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surface.withOpacity(0.6),
                    contentPadding: const EdgeInsets.all(10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: scheme.primary),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text('Закреплено',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant)),
              ),
              Expanded(
                child: apps.isEmpty
                    ? Center(
                        child: Text('Ничего не найдено',
                            style:
                                TextStyle(color: scheme.onSurfaceVariant)))
                    : GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        childAspectRatio: 0.85,
                        children: <Widget>[
                          for (final app in apps)
                            InkWell(
                              onTap: () => widget.onOpen(app),
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color:
                                          scheme.primary.withOpacity(0.14),
                                    ),
                                    child: Icon(app.icon,
                                        size: 22, color: scheme.primary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(app.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primary,
                      child: const Text('z',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('zik',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('zik@zikos',
                            style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Выключение',
                      icon: const Icon(Icons.power_settings_new, size: 20),
                      onPressed: () => _power(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _power(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выключить ZikOS?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Выключить')),
        ],
      ),
    );
    if (ok == true) {
      SystemNavigator.pop();
    }
  }
}
