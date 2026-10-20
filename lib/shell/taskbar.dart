import 'dart:ui' show ImageFilter;

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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: scheme.surface.withOpacity(0.72),
          child: Container(
            height: kTaskbarHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Spacer(),
                _StartButton(onPressed: onStart, active: menuOpen),
                const SizedBox(width: 6),
                for (final app in Apps.all) _TaskAppIcon(app: app),
                const Spacer(),
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
                const SizedBox(width: 8),
              ],
            ),
          ),
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
    return Tooltip(
      message: 'Пуск',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active
                ? scheme.primary.withOpacity(0.16)
                : Colors.transparent,
          ),
          child: Icon(Icons.dashboard_rounded,
              size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _TaskAppIcon extends StatelessWidget {
  const _TaskAppIcon({required this.app});
  final AppDefinition app;

  @override
  Widget build(BuildContext context) {
    final wm = WindowManager.instance;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: wm,
      builder: (context, _) {
        final w = wm.find(app.id);
        final running = w != null;
        final focused = running && !w!.minimized && w.z == wm.topZ;
        return Tooltip(
          message: app.title,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    if (w == null) {
                      wm.open(app);
                    } else if (w.minimized) {
                      wm.toggleMinimize(w);
                    } else if (focused) {
                      wm.toggleMinimize(w);
                    } else {
                      wm.focus(w);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 42,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: focused
                          ? scheme.primary.withOpacity(0.18)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      app.icon,
                      size: 20,
                      color: running
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: running ? (focused ? 16.0 : 8.0) : 0.0,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
