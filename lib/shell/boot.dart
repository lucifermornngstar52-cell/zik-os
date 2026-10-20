import 'dart:async';

import 'package:flutter/material.dart';

import 'desktop.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final List<String> _script = <String>[
    'ZIK BIOS v2.41 — W1027 Tablet PC',
    'Memory test: 4096 MB ......... OK',
    'Storage: eMMC 32 GB .......... OK',
    'Battery: OK | Backlight: OK',
    '',
    'Loading zikos-kernel 1.0.0 ...',
    '[ OK ] Mounting /home',
    '[ OK ] Starting window manager',
    '[ OK ] Starting shell services',
    '[ OK ] Loading desktop environment',
    '',
    'Welcome to ZikOS.',
  ];
  int _shown = 0;
  bool _finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_shown >= _script.length) {
        _timer?.cancel();
        Timer(const Duration(milliseconds: 900), _finish);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DesktopShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: const Color(0xFF3B82F6)),
                    alignment: Alignment.center,
                    child: const Text('Z',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  const Text('ZikOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (int i = 0; i < _shown && i < _script.length; i++)
                      Text(
                        _script[i],
                        style: const TextStyle(
                            color: Color(0xFF7DE3A3),
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.6),
                      ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_shown / _script.length).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Нажмите в любом месте, чтобы пропустить',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
