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
  final plans = await getAllSubs(username, password, http);
  print('Got data from dsbuntis, saving...');
  final json = jsonEncode({
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
    'plans': plans,
    'cache': cache,
  });
  await File('$output/${now.millisecondsSinceEpoch / 1000}.json')
      .writeAsString(json);
  print('Saved to file.');
}

void main() async {
  final config = jsonDecode(File('/etc/aggregamusrc.json').readAsStringSync());
  String username = config['username'];
  String password = config['password'];
  String output = config['output'];
  String proxy = config['proxy'];
  while (true) {
    await sample(username, password, output, proxy);
    sleep(Duration(minutes: 5));
  }
}
