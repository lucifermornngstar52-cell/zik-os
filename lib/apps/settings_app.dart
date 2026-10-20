import 'package:flutter/material.dart';

import '../core/settings.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (context, _) {
        final s = Settings.instance;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            Text('Настройки', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _card(
              context,
              'Обои',
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (int i = 0; i < Settings.wallpapers.length; i++)
                    GestureDetector(
                      onTap: () => s.wallpaperIndex = i,
                      child: Container(
                        width: 74,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                              colors: Settings.wallpapers[i]),
                          border: Border.all(
                              color: s.wallpaperIndex == i
                                  ? scheme.primary
                                  : Colors.transparent,
                              width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _card(
              context,
              'Акцентный цвет',
              Wrap(
                spacing: 10,
                children: <Widget>[
                  for (int i = 0; i < Settings.accents.length; i++)
                    GestureDetector(
                      onTap: () => s.accentIndex = i,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Settings.accents[i],
                          border: Border.all(
                              color: s.accentIndex == i
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _card(
              context,
              'Оформление',
              SwitchListTile(
                  title: const Text('Тёмная тема'),
                  value: s.dark,
                  onChanged: (v) => s.dark = v),
            ),
            _card(
              context,
              'О системе',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _kv(context, 'ОС', 'ZikOS 1.0.0'),
                  _kv(context, 'Устройство', 'ZIK W1027'),
                  _kv(context, 'Пользователь', 'zik'),
                  _kv(context, 'Движок', 'Flutter'),
                  _kv(context, 'Хранилище', 'локальное, /home'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Собрано специально для БИМ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(k,
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 12)),
          ),
          Expanded(
              child: Text(v, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
