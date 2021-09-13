import 'dart:convert';
import 'dart:io';

import 'package:dsbuntis/dsbuntis.dart';
import 'package:schttp/schttp.dart';

Future<void> sample(Map config) async {
  final now = DateTime.now();
  final cache = <List>[];
  final http = ScHttpClient(
    setCache: (id, resp, ttl) => cache.add([id, resp, ttl]),
    setPostCache: (id, body, resp, ttl) => cache.add([id, body, resp, ttl]),
    setBinCache: (id, resp, ttl) => cache.add([id, resp, ttl]),
    findProxy: (_) => 'PROXY ${config['proxy']}',
  );
  final plans =
      await getAllSubs(config['username'], config['password'], http: http);
  print('Got data from dsbuntis, saving...');
  final json = jsonEncode({
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
    'plans': plans,
    'cache': cache,
  });
  await File(config['output'] +
          '/${(now.millisecondsSinceEpoch / 1000).round()}.json')
      .writeAsString(json);
  print('Saved to file.');
}

Future<void> cleanup(String output) async {
  final files = await Directory(output)
      .list()
      .where((e) => e.path.endsWith('.json') && e is File)
      .toList();
  if (files.length < 200) return;
  print('Cleaning up...');
  final id = DateTime.now().millisecondsSinceEpoch;
  final pr = await Process.run(
      '/bin/sh',
      [
        '-c',
        'tar cJvf $output/$id.tar.xz ' +
            files.map((e) => e.absolute.path).reduce((p, e) => '$p $e')
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8);
  print(pr.stdout);
  print(pr.stderr);
  if (pr.exitCode != 0) return;
  files.forEach((e) => e.deleteSync());
}

void main() async {
  final config = jsonDecode(File('/etc/aggregamusrc.json').readAsStringSync());
  while (true) {
    await sample(config);
    await cleanup(config['output']);
    sleep(Duration(minutes: 5));
  }
}
