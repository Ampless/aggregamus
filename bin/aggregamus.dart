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
  final http = ScHttpClient((_) => null, (id, resp, ttl) => cache[id] = resp);
  final plans = getAllSubs(
    username,
    password,
    http,
    'http://$proxy/mobileapi.dsbcontrol.de',
  );
  final json = jsonEncode({
    'unixts': now.millisecondsSinceEpoch,
    'ts': now.toIso8601String(),
    'plans': plans,
    'cache': cache,
  });
  await File('$output/${now.millisecondsSinceEpoch / 1000}.json')
      .writeAsString(json);
}

void main() {
  final config = jsonDecode(File('/etc/aggregamusrc.json').readAsStringSync());
  String username = config['username'];
  String password = config['password'];
  String output = config['output'];
  String proxy = config['proxy'];
  while (true) {
    sample(username, password, output, proxy);
    sleep(Duration(minutes: 5));
  }
}
