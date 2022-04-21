import 'dart:convert';
import 'dart:io';

import 'package:dsbuntis/dsbuntis.dart';
import 'package:schttp/schttp.dart';

Future<void> sample(Map config) async {
  final now = DateTime.now();
  final json = {
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
  };
  try {
    final cache = <List>[];
    final http = ScHttpClient(
      setCache: (u, resp, ttl) =>
          cache.add([u.toString(), resp, ttl.toString()]),
      setPostCache: (u, body, resp, ttl) =>
          cache.add([u.toString(), body, resp, ttl.toString()]),
      setBinCache: (u, resp, ttl) =>
          cache.add([u.toString(), resp, ttl.toString()]),
      findProxy: (_) => 'PROXY ${config['proxy']}',
    );
    final plans =
        await getAllSubs(config['username'], config['password'], http: http);
    print('Got data from dsbuntis.');
    json['plans'] = plans;
    json['cache'] = cache;
  } catch (e) {
    print('Error.');
    json['error'] = e is Error ? '$e\n${e.stackTrace}' : e;
  }
  await File(config['output'] +
          '/${(now.millisecondsSinceEpoch / 1000).round()}.json')
      .writeAsString(jsonEncode(json));
  print('Saved to file.');
}

Future<void> cleanup(String output) async {
  final files = await Directory(output)
      .list()
      .where((e) => e.path.endsWith('.json') && e is File)
      .toList();
  if (files.length < 200) return;
  print('Cleaning up...');
  final id = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  final pr = await Process.run(
      '/usr/bin/env',
      [
        'tar',
        'cJvf',
        '$output/$id.tar.xz',
        ...files.map((e) => e.absolute.path),
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8);
  print(pr.stdout);
  print(pr.stderr);
  if (pr.exitCode != 0) return;
  await Future.wait(files.map((e) => e.delete()));
}

void main() async {
  final config = jsonDecode(File('/etc/aggregamusrc.json').readAsStringSync());
  while (true) {
    await sample(config);
    await cleanup(config['output']);
    sleep(Duration(minutes: 5));
  }
}
