import 'dart:convert';
import 'dart:io';

import 'package:dsbuntis/dsbuntis.dart';
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;
import 'package:prometheus_client_shelf/shelf_handler.dart';
import 'package:schttp/schttp.dart';
import 'package:shelf/shelf_io.dart';

final uncompressedSaves = Gauge(
  name: 'aggregamus_uncompressed',
  help: 'The number of saved JSONs that weren\'t compressed already.',
);

Future<void> sample(Map config) async {
  final now = DateTime.now();
  final json = {
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
  };
  try {
    final cache = <List>[];
    final http = ScHttpClient(
      setCache: (u, _, resp, ttl) =>
          cache.add([u.toString(), resp, ttl.toString()]),
      setPostCache: (u, body, _, resp, ttl) =>
          cache.add([u.toString(), body, resp, ttl.toString()]),
      setBinCache: (u, _, resp, ttl) =>
          cache.add([u.toString(), resp, ttl.toString()]),
      findProxy: config.containsKey('proxy')
          ? (_) => 'PROXY ${config['proxy']}'
          : null,
    );
    final plans =
        await getAllSubs(config['username'], config['password'], http: http);
    print('Got data from dsbuntis');
    json['plans'] = plans;
    json['cache'] = cache;
  } catch (e, st) {
    stderr.writeln('$e');
    json['error'] = '$e\n$st';
  }
  await File(config['output'] +
          '/${(now.millisecondsSinceEpoch / 1000).round()}.json')
      .writeAsString(jsonEncode(json));
  uncompressedSaves.inc();
  print('Saved to file');
}

Future<void> cleanup(String output) async {
  final files = await Directory(output)
      .list()
      .where((e) => e.path.endsWith('.json') && e is File)
      .toList();
  if (files.length < 200) return;
  print('Cleaning up');
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
  uncompressedSaves.dec(uncompressedSaves.value);
}

Future<void> monitor(int monitoringPort) async {
  runtime_metrics.register();
  uncompressedSaves.register();

  final server =
      await serve(prometheusHandler(), InternetAddress.anyIPv6, monitoringPort);
  print(
      'Serving metrics at http://${server.address.host}:${server.port}/metrics');
}

void main() async {
  final config = jsonDecode(File('/etc/aggregamusrc.json').readAsStringSync());
  await monitor(config['monitoring_port']);
  while (true) {
    await sample(config);
    await cleanup(config['output']);
    await Future.delayed(Duration(minutes: 5));
  }
}
