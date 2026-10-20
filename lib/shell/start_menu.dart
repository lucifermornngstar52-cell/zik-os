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
    return Material(
      borderRadius: BorderRadius.circular(14),
      elevation: 14,
      color: scheme.surface.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Поиск приложений...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: <Widget>[
                  for (final app in apps)
                    ListTile(
                      leading: Icon(app.icon, color: scheme.primary),
                      title: Text(app.title),
                      onTap: () => widget.onOpen(app),
                    ),
                  if (apps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ничего не найдено',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Row(
              children: <Widget>[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primary,
                  child: const Text('z',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('zik',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('ZikOS 1.0.0',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Выключение',
                  icon: const Icon(Icons.power_settings_new),
                  onPressed: () => _power(context),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
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
