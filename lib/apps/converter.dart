import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: const <Widget>[
          TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: 'Единицы'),
              Tab(text: 'Системы счисления'),
              Tab(text: 'Текст'),
              Tab(text: 'Время'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _UnitsTab(),
                _BasesTab(),
                _TextTab(),
                _TimeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsTab extends StatefulWidget {
  const _UnitsTab();

  @override
  State<_UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<_UnitsTab> {
  static const Map<String, Map<String, double>> _units =
      <String, Map<String, double>>{
    'Длина': <String, double>{
      'мм': 0.001, 'см': 0.01, 'м': 1, 'км': 1000,
      'дюйм': 0.0254, 'фут': 0.3048, 'ярд': 0.9144, 'миля': 1609.344,
    },
    'Масса': <String, double>{
      'г': 0.001, 'кг': 1, 'т': 1000, 'фунт': 0.45359237, 'унция': 0.0283495,
    },
    'Данные': <String, double>{
      'Байт': 1, 'КБайт': 1024, 'МБайт': 1048576, 'ГБайт': 1073741824, 'ТБайт': 1099511627776,
    },
    'Скорость': <String, double>{
      'м/с': 1, 'км/ч': 0.2777778, 'миль/ч': 0.44704, 'узел': 0.5144444,
    },
    'Время': <String, double>{
      'сек': 1, 'мин': 60, 'час': 3600, 'день': 86400, 'неделя': 604800,
    },
    'Температура': <String, double>{'°C': 1, '°F': 1, 'K': 1},
  };

  String _cat = 'Длина';
  String _from = 'м';
  String _to = 'фут';
  final TextEditingController _value = TextEditingController(text: '1');

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  List<String> get _keysOfCat => _units[_cat]!.keys.toList();

  String _fmt(double x) {
    if (x == x.roundToDouble() && x.abs() < 1e12) return x.round().toString();
    return x
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String get _result {
    final v = double.tryParse(_value.text.replaceAll(',', '.'));
    if (v == null) return '—';
    if (_cat == 'Температура') {
      double c;
      if (_from == '°C') {
        c = v;
      } else if (_from == '°F') {
        c = (v - 32) / 1.8;
      } else {
        c = v - 273.15;
      }
      double r;
      if (_to == '°C') {
        r = c;
      } else if (_to == '°F') {
        r = c * 1.8 + 32;
      } else {
        r = c + 273.15;
      }
      return _fmt(r);
    }
    final f = _units[_cat]![_from]!;
    final t = _units[_cat]![_to]!;
    return _fmt(v * f / t);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _cat,
            decoration: const InputDecoration(
                labelText: 'Категория', border: OutlineInputBorder()),
            items: <DropdownMenuItem<String>>[
              for (final k in _units.keys) DropdownMenuItem<String>(value: k, child: Text(k)),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _cat = v;
                  final ks = _units[v]!.keys.toList();
                  _from = ks.first;
                  _to = ks.length > 1 ? ks[1] : ks.first;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Значение', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: const InputDecoration(
                      labelText: 'Из', border: OutlineInputBorder()),
                  items: <DropdownMenuItem<String>>[
                    for (final k in _keysOfCat) DropdownMenuItem<String>(value: k, child: Text(k)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _from = v);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Поменять',
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _to,
                  decoration: const InputDecoration(
                      labelText: 'В', border: OutlineInputBorder()),
                  items: <DropdownMenuItem<String>>[
                    for (final k in _keysOfCat) DropdownMenuItem<String>(value: k, child: Text(k)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _to = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  Text(
                    _result,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold, color: scheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('$_from → $_to',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasesTab extends StatefulWidget {
  const _BasesTab();

  @override
  State<_BasesTab> createState() => _BasesTabState();
}

class _BasesTabState extends State<_BasesTab> {
  final TextEditingController _input = TextEditingController(text: '255');
  int _base = 10;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  BigInt? get _val {
    final t = _input.text.trim();
    if (t.isEmpty) return null;
    try {
      return BigInt.parse(t, radix: _base);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const labels = <int, String>{2: 'BIN', 8: 'OCT', 10: 'DEC', 16: 'HEX'};
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _input,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Число', border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<int>(
                value: _base,
                items: const <DropdownMenuItem<int>>[
                DropdownMenuItem<int>(value: 2, child: Text('BIN 2')),
                DropdownMenuItem<int>(value: 8, child: Text('OCT 8')),
                DropdownMenuItem<int>(value: 10, child: Text('DEC 10')),
                DropdownMenuItem<int>(value: 16, child: Text('HEX 16')),
              ],
                onChanged: (v) {
                  if (v != null) setState(() => _base = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final b in <int>[2, 8, 10, 16])
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 48,
                      child: Text(labels[b]!,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                              fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(
                        _val?.toRadixString(b) ?? '—',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextTab extends StatefulWidget {
  const _TextTab();

  @override
  State<_TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<_TextTab> {
  final TextEditingController _in = TextEditingController();
  final TextEditingController _out = TextEditingController();

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  void _apply(int op) {
    final s = _in.text;
    String r;
    try {
      switch (op) {
        case 0:
          r = base64.encode(utf8.encode(s));
          break;
        case 1:
          r = utf8.decode(base64.decode(s.trim()));
          break;
        case 2:
          r = Uri.encodeComponent(s);
          break;
        case 3:
          r = Uri.decodeComponent(s);
          break;
        case 4:
          r = s.toUpperCase();
          break;
        case 5:
          r = s.toLowerCase();
          break;
        case 6:
          r = String.fromCharCodes(s.runes.toList().reversed);
          break;
        default:
          r = s;
      }
      _out.text = r;
    } catch (e) {
      _out.text = 'Ошибка: некорректный ввод';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _in,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Ввод',
                border: OutlineInputBorder(),
                alignLabelWithHint: true),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(onPressed: () => _apply(0), child: const Text('Base64 ↗')),
              OutlinedButton(onPressed: () => _apply(1), child: const Text('Base64 ↘')),
              OutlinedButton(onPressed: () => _apply(2), child: const Text('URL ↗')),
              OutlinedButton(onPressed: () => _apply(3), child: const Text('URL ↘')),
              OutlinedButton(onPressed: () => _apply(4), child: const Text('ВЕРХНИЙ')),
              OutlinedButton(onPressed: () => _apply(5), child: const Text('нижний')),
              OutlinedButton(onPressed: () => _apply(6), child: const Text('Реверс')),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _out,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Результат',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _out.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Скопировано'),
                          duration: Duration(seconds: 1)));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTab extends StatefulWidget {
  const _TimeTab();

  @override
  State<_TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<_TimeTab> {
  final TextEditingController _ts = TextEditingController();
  final TextEditingController _dt = TextEditingController();

  @override
  void dispose() {
    _ts.dispose();
    _dt.dispose();
    super.dispose();
  }

  String _p2(int n) => n.toString().padLeft(2, '0');

  String get _fromTs {
    final t = int.tryParse(_ts.text.trim());
    if (t == null) return '—';
    final d = t > 100000000000
        ? DateTime.fromMillisecondsSinceEpoch(t)
        : DateTime.fromMillisecondsSinceEpoch(t * 1000);
    return '${_p2(d.day)}.${_p2(d.month)}.${d.year} ${_p2(d.hour)}:${_p2(d.minute)}:${_p2(d.second)}';
  }

  String get _fromDate {
    final s = _dt.text.trim();
    if (s.isEmpty) return '—';
    final d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (d == null) return '—';
    return (d.millisecondsSinceEpoch ~/ 1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Метка времени → Дата',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ts,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: '1760851200', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(_fromTs,
                      style: TextStyle(
                          fontSize: 17,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Дата → Метка времени',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dt,
                    decoration: const InputDecoration(
                        hintText: '2026-10-20 21:45',
                        border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(_fromDate,
                      style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'monospace',
                          color: scheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
