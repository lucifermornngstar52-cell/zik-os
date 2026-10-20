import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/fs_service.dart';
import 'core/settings.dart';
import 'shell/boot.dart';

/// Момент старта системы — для uptime в neofetch.
final DateTime bootAt = DateTime.now();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await FS.init();
  await Settings.load();
  runApp(const ZikOSApp());
}

class ZikOSApp extends StatelessWidget {
  const ZikOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (context, _) {
        final scheme = ColorScheme.fromSeed(
          seedColor: Settings.instance.accent,
          brightness: Settings.instance.brightness,
        );
        return MaterialApp(
          title: 'ZikOS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorScheme: scheme),
          home: const BootScreen(),
        );
      },
    );
  }
}
