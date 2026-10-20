import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FS {
  static late Directory root;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    root = Directory('${docs.path}/home');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    _seed();
  }

  static void _seed() {
    final readme = File(join('readme.txt'));
    if (!readme.existsSync()) {
      readme.writeAsStringSync(
        'ZikOS 1.0.0 — мини-ОС для планшета.\n\n'
        'Это твой домашний каталог (/home).\n'
        'Терминал, файловый менеджер и редактор кода работают с этими же файлами.\n'
        'Папка projects — для кода. Открой projects/demo.html в приложении «Код» и нажми «Превью».\n');
    }
    final projects = Directory(join('projects'));
    if (!projects.existsSync()) projects.createSync();
    final demo = File(join('projects/demo.html'));
    if (!demo.existsSync()) demo.writeAsStringSync(demoHtml);
    final hello = File(join('projects/hello.py'));
    if (!hello.existsSync()) {
      hello.writeAsStringSync(
          '# ZikOS поддерживает подсветку синтаксиса\ndef hello():\n    print("Привет из ZikOS!")\n\nhello()\n');
    }
  }

  static String join(String relPath) =>
      relPath.isEmpty ? root.path : '$root.path/$relPath';

  static String normalize(String relPath) {
    final parts = <String>[];
    for (final seg in relPath.split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(seg);
    }
    return parts.join('/');
  }

  static bool exists(String relPath) =>
      FileSystemEntity.typeSync(join(relPath)) != FileSystemEntityType.notFound;

  static bool isDir(String relPath) => Directory(join(relPath)).existsSync();

  static List<FileSystemEntity> list(String relPath) {
    final dir = Directory(join(relPath));
    if (!dir.existsSync()) return <FileSystemEntity>[];
    final items = dir.listSync().where((e) {
      final n = e.path.split('/').last;
      return n.isNotEmpty && !n.startsWith('.');
    }).toList()
      ..sort((a, b) {
        final ad = a is Directory ? 0 : 1;
        final bd = b is Directory ? 0 : 1;
        return ad != bd ? ad - bd : a.path.compareTo(b.path);
      });
    return items;
  }

  static String read(String relPath) => File(join(relPath)).readAsStringSync();

  static void write(String relPath, String content) {
    final f = File(join(relPath));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  static void mkdir(String relPath) =>
      Directory(join(relPath)).createSync(recursive: true);

  static void delete(String relPath) {
    final t = FileSystemEntity.typeSync(join(relPath));
    if (t == FileSystemEntityType.directory) {
      Directory(join(relPath)).deleteSync(recursive: true);
    } else if (t == FileSystemEntityType.file) {
      File(join(relPath)).deleteSync();
    }
  }

  static void rename(String from, String to) {
    final dir = Directory(join(from));
    final src = dir.existsSync() ? dir : File(join(from));
    src.renameSync(join(to));
  }

  static String entityName(FileSystemEntity e) => e.path.split('/').last;

  static String relPathOf(FileSystemEntity e) => e.path.substring(
      root.path.length + (e.path.length > root.path.length ? 1 : 0));

  static const String demoHtml = '''
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<title>ZikOS Demo</title>
<style>
  body { font-family: sans-serif; background: linear-gradient(135deg, #0f172a, #312e81); color: #e2e8f0; display: flex; min-height: 100vh; align-items: center; justify-content: center; }
  .card { background: rgba(255,255,255,.06); padding: 32px 40px; border-radius: 16px; text-align: center; }
  h1 { color: #93c5fd; margin: 0 0 8px; }
  button { margin-top: 16px; padding: 10px 22px; border: 0; border-radius: 10px; background: #3b82f6; color: white; font-size: 15px; }
  p { margin: 6px 0; }
</style>
</head>
<body>
  <div class="card">
    <h1>Привет из ZikOS!</h1>
    <p>Это живой предпросмотр HTML прямо на планшете.</p>
    <button onclick="onClick(this)">Нажми меня</button>
    <p id="out"></p>
  </div>
  <script>
    function onClick(btn) {
      document.getElementById('out').textContent = 'JS работает! ' + new Date().toLocaleTimeString();
    }
  </script>
</body>
</html>
''';
}
