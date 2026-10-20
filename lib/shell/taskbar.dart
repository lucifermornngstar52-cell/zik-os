import 'package:flutter/material.dart';

import '../core/settings.dart';
import 'app_registry.dart';
import 'window_manager.dart';

const double kTaskbarHeight = 48;

class Taskbar extends StatelessWidget {
  const Taskbar({super.key, required this.onStart, required this.menuOpen});
  final VoidCallback onStart;
  final bool menuOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withOpacity(0.94),
      elevation: 8,
      child: SizedBox(
        height: kTaskbarHeight,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _StartButton(onPressed: onStart, active: menuOpen),
            ),
            Container(width: 1, height: 26, color: scheme.outlineVariant),
            const SizedBox(width: 4),
            for (final app in Apps.all)
              IconButton(
                tooltip: app.title,
                icon: Icon(app.icon, size: 20),
                onPressed: () => WindowManager.instance.open(app),
              ),
            const SizedBox(width: 4),
            Container(width: 1, height: 26, color: scheme.outlineVariant),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedBuilder(
                animation: WindowManager.instance,
                builder: (context, _) {
                  final wm = WindowManager.instance;
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final w in wm.windows)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
                          child: _TaskButton(window: w),
                        ),
                    ],
                  );
                },
              ),
            ),
            const _Clock(),
            AnimatedBuilder(
              animation: Settings.instance,
              builder: (context, _) {
                return IconButton(
                  tooltip: 'Тема',
                  icon: Icon(Settings.instance.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined),
                  onPressed: () =>
                      Settings.instance.dark = !Settings.instance.dark,
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed, required this.active});
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? scheme.primary.withOpacity(0.8) : scheme.primary,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.dashboard_rounded, size: 18, color: scheme.onPrimary),
            const SizedBox(width: 6),
            Text('Пуск',
                style: TextStyle(
                    color: scheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _TaskButton extends StatelessWidget {
  const _TaskButton({required this.window});
  final OSWindow window;

  @override
  Widget build(BuildContext context) {
    final wm = WindowManager.instance;
    final scheme = Theme.of(context).colorScheme;
    final focused = !window.minimized && window.z == wm.topZ;
    return InkWell(
      onTap: () {
        if (window.minimized) {
          wm.toggleMinimize(window);
        } else if (focused) {
          wm.toggleMinimize(window);
        } else {
          wm.focus(window);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: focused ? scheme.primary.withOpacity(0.22) : scheme.surface,
          border: Border.all(
              color: focused ? scheme.primary : scheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(window.app.icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(window.app.title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<DateTime>(
      initialData: DateTime.now(),
      stream: Stream<DateTime>.periodic(
          const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snap) {
        final now = snap.data!;
        const wd = <String>['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        final day = now.day.toString().padLeft(2, '0');
        final month = now.month.toString().padLeft(2, '0');
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${wd[now.weekday - 1]} $day.$month  $hh:$mm',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
          ),
        );
      },
    );
  }
}
