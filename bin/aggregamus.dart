import 'dart:convert';
import 'dart:io';

import 'package:dsbuntis/dsbuntis.dart';
import 'package:schttp/schttp.dart';

Future<void> sample(
  String username,
  String password,
  String output,
  String proxy,
) async {
  final now = DateTime.now();
  final cache = <String, String>{};
  final http = ScHttpClient(
    setCache: (id, resp, ttl) => cache[id] = resp,
    findProxy: (_) => 'PROXY $proxy',
  );
  final plans = await getAllSubs(username, password, http: http);
  print('Got data from dsbuntis, saving...');
  final json = jsonEncode({
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
    'plans': plans,
    'cache': cache,
  });
  await File('$output/${(now.millisecondsSinceEpoch / 1000).round()}.json')
      .writeAsString(json);
  print('Saved to file.');
}

Future<void> cleanup(String output) async {
  print('Cleaning up...');
  final id = DateTime.now().millisecondsSinceEpoch;
  final files = await Directory(output).list().where((e) => e is File).toList();
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
  String username = config['username'];
  String password = config['password'];
  String output = config['output'];
  String proxy = config['proxy'];
  var count = 0;
  while (true) {
    await sample(username, password, output, proxy);
    if (count % 300 == 299) await cleanup(output);
    count++;
    sleep(Duration(minutes: 5));
  }
}
