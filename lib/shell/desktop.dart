import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/settings.dart';
import 'app_registry.dart';
import 'start_menu.dart';
import 'taskbar.dart';
import 'window.dart';
import 'window_manager.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(bottom: false, child: _DesktopArea()));
  }
}

class _DesktopArea extends StatefulWidget {
  const _DesktopArea();

  @override
  State<_DesktopArea> createState() => _DesktopAreaState();
}

class _DesktopAreaState extends State<_DesktopArea> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final wm = WindowManager.instance;
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        return AnimatedBuilder(
          animation: wm,
          builder: (context, _) {
            final workHeight = math.max(200.0, area.height - kTaskbarHeight);
            final visible = wm.windows.where((w) => !w.minimized).toList()
              ..sort((a, b) => a.z.compareTo(b.z));
            return Stack(
              children: <Widget>[
                const Wallpaper(),
                Positioned(
                  top: 10,
                  left: 10,
                  child: DesktopIcons(onOpen: (app) => wm.open(app)),
                ),
                for (final w in visible)
                  w.maximized
                      ? Positioned(
                          left: 0,
                          top: 0,
                          width: area.width,
                          height: workHeight,
                          child: OSWindowFrame(window: w),
                        )
                      : Positioned(
                          left: w.position.dx
                              .clamp(0.0, math.max(0.0, area.width - 120))
                              .toDouble(),
                          top: w.position.dy
                              .clamp(0.0, math.max(0.0, workHeight - 48))
                              .toDouble(),
                          width: w.size.width
                              .clamp(320.0, math.max(320.0, area.width))
                              .toDouble(),
                          height: w.size.height
                              .clamp(220.0, math.max(220.0, workHeight))
                              .toDouble(),
                          child: OSWindowFrame(window: w),
                        ),
                if (_menuOpen)
                  Positioned(
                    left: 8,
                    bottom: kTaskbarHeight + 8,
                    width: 380,
                    height: 440,
                    child: StartMenu(onOpen: (app) {
                      setState(() => _menuOpen = false);
                      wm.open(app);
                    }),
                  ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: TaskbarHost(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TaskbarHost extends StatefulWidget {
  const TaskbarHost({super.key});

  @override
  State<TaskbarHost> createState() => _TaskbarHostState();
}

class _TaskbarHostState extends State<TaskbarHost> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Taskbar(
      menuOpen: _open,
      onStart: () => setState(() => _open = !_open),
    );
  }
}

class Wallpaper extends StatelessWidget {
  const Wallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (context, _) {
        final idx =
            Settings.instance.wallpaperIndex.clamp(0, Settings.wallpapers.length - 1);
        final colors = Settings.wallpapers[idx];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: CustomPaint(size: Size.infinite, painter: _GridPainter()),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DesktopIcons extends StatelessWidget {
  const DesktopIcons({super.key, required this.onOpen});
  final void Function(AppDefinition app) onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final app in Apps.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onOpen(app),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(app.icon, color: scheme.primary, size: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        shadows: <Shadow>[Shadow(blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
