import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:nireekshana/db/database.dart';
import 'package:nireekshana/domain/app_sources.dart';
import 'package:nireekshana/domain/connections.dart';
import 'package:nireekshana/domain/counters.dart';
import 'package:nireekshana/domain/firewall.dart';
import 'package:nireekshana/domain/probe.dart';
import 'package:nireekshana/domain/themes.dart';

/// A fresh in-memory database (the bundled SQLite3MultipleCiphers works
/// unkeyed in memory).
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// The built-in themes, read from the repository.
List<NetTheme> builtInThemes() => parseBuiltInThemes(File('themes/builtin.json').readAsStringSync());

/// Counters that grow by a steady amount each reading: 1.2 MB down and
/// 300 kB up a second on Wi-Fi, a little on a VPN that is never counted.
class FakeProbe implements NetProbe {
  int _n = 0;

  /// Readings are a second apart whatever the test clock does.
  final _start = DateTime.now();

  @override
  Future<Sample> sample() {
    final n = _n++;
    return Future.value(
      Sample(_start.add(Duration(seconds: n)), [
        Iface(name: 'wlan0', kind: 'wifi', rx: 5000000000 + n * 1200000, tx: 800000000 + n * 300000),
        Iface(name: 'enp3s0', kind: 'ethernet', rx: 0, tx: 0, up: false),
        Iface(name: 'wg0', kind: 'vpn', rx: 10000 + n * 1000, tx: 10000 + n * 500),
      ], boot: 'test-boot'),
    );
  }
}

/// A firewall with a few rules, which records the changes asked of it.
class FakeFirewall extends Firewall {
  FakeFirewall();
  final changes = <List<String>>[];

  static const export = '''
{
  "generated": "2026-10-26T10:00:00Z",
  "rules": [
    {"file": "000-nireekshana-block-domains.json", "action": "deny", "operator": {"type": "lists"}},
    {"file": "002-nireekshana-allow-dns.json", "name": "allow-dns", "action": "allow",
     "operator": {"operand": "dest.port", "data": "53"}},
    {"file": "firefox.json", "action": "allow", "enabled": true,
     "operator": {"type": "list", "list": [
       {"operand": "process.path", "data": "/usr/lib/firefox/firefox"},
       {"operand": "dest.host", "data": "example.com"}]}},
    {"file": "curl.json", "action": "deny",
     "operator": {"operand": "process.path", "data": "/usr/bin/curl"}}
  ],
  "lists": {"block-domains": ["ads.example.net"], "allow-domains": [], "block-nets": ["203.0.113.0/24"], "allow-nets": []}
}''';

  @override
  Future<FirewallStatus> status() =>
      Future.value(const FirewallStatus(helper: true, export: true, daemon: 'active'));

  @override
  Future<({List<RuleItem> items, String generated})> rules() => Future.value(parseRulesExport(export)!);

  @override
  Future<void> change(List<String> args) async => changes.add(args);
}

/// A handful of made-up sockets.
const sampleConnections = [
  Connection(
    protocol: 'tcp',
    local: '192.168.1.20',
    localPort: 51000,
    remote: '93.184.216.34',
    remotePort: 443,
    state: 'established',
    pid: 4242,
    path: '/usr/lib/firefox/firefox',
    program: 'firefox',
  ),
  Connection(
    protocol: 'tcp6',
    local: '::1',
    localPort: 51001,
    remote: '2606:2800:220:1::1',
    remotePort: 443,
    state: 'established',
    pid: 4242,
    path: '/usr/lib/firefox/firefox',
    program: 'firefox',
  ),
  Connection(
    protocol: 'udp',
    local: '0.0.0.0',
    localPort: 5353,
    pid: 900,
    path: '/usr/bin/avahi-daemon',
    program: 'avahi-daemon',
  ),
  Connection(
    protocol: 'tcp',
    local: '192.168.1.20',
    localPort: 52000,
    remote: '192.168.1.1',
    remotePort: 80,
    state: 'established',
  ),
];

/// A per-app record that answers from a list, or says it is not set up.
class FakeAppSource implements AppSource {
  FakeAppSource(this.rows, {this.ready = true});
  final List<AppCount> rows;
  bool ready;
  final asked = <int>[];

  @override
  String get title => 'test apps';

  @override
  Future<bool> available() async => ready;

  @override
  Future<List<AppCount>> read({int days = 31}) async {
    asked.add(days);
    return rows;
  }
}
