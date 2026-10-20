import 'package:flutter/material.dart';

import 'window_manager.dart';

class OSWindowFrame extends StatelessWidget {
  const OSWindowFrame({super.key, required this.window});
  final OSWindow window;

  @override
  Widget build(BuildContext context) {
    final wm = WindowManager.instance;
    final scheme = Theme.of(context).colorScheme;
    final focused = window.z == wm.topZ;
    return GestureDetector(
      onTap: () => wm.focus(window),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: focused ? 12 : 4,
        color: scheme.surface,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  _TitleBar(window: window, focused: focused),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey<String>('${window.app.id}|${window.argument}'),
                      child: window.app.builder(window.argument),
                    ),
                  ),
                ],
              ),
              if (!window.maximized)
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 24,
                  height: 24,
                  child: GestureDetector(
                    onPanUpdate: (d) => wm.resize(window, d.delta),
                    child: CustomPaint(
                      size: const Size(24, 24),
                      painter: _ResizePainter(scheme.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.window, required this.focused});
  final OSWindow window;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final wm = WindowManager.instance;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanUpdate: (d) {
        if (!window.maximized) wm.move(window, d.delta);
      },
      onDoubleTap: () => wm.toggleMaximize(window),
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(
          color: focused
              ? scheme.primary.withOpacity(0.15)
              : scheme.surface.withOpacity(0.6),
        ),
        child: Row(
          children: <Widget>[
            Icon(window.app.icon, size: 15, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                window.app.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface),
              ),
            ),
            _CircleBtn(
              icon: Icons.remove,
              onTap: () => wm.toggleMinimize(window),
              color: scheme.onSurface.withOpacity(0.07),
              fg: scheme.onSurface,
            ),
            const SizedBox(width: 5),
            _CircleBtn(
              icon: window.maximized ? Icons.filter_none : Icons.crop_square,
              onTap: () => wm.toggleMaximize(window),
              color: scheme.onSurface.withOpacity(0.07),
              fg: scheme.onSurface,
            ),
            const SizedBox(width: 5),
            _CircleBtn(
              icon: Icons.close,
              onTap: () => wm.close(window),
              color: Colors.redAccent,
              fg: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn(
      {required this.icon, required this.onTap, required this.color, required this.fg});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, size: 14, color: fg),
      ),
    );
  }
}

class _ResizePainter extends CustomPainter {
  _ResizePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(size.width - 5, size.height - 11), Offset(size.width - 11, size.height - 5), paint);
    canvas.drawLine(
        Offset(size.width - 5, size.height - 17), Offset(size.width - 17, size.height - 5), paint);
  }

  @override
  bool shouldRepaint(covariant _ResizePainter oldDelegate) => false;
}
