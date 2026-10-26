import 'dart:io';

import 'windows_net.dart';

/// One open socket and the program behind it.
class Connection {
  const Connection({
    required this.protocol,
    required this.local,
    required this.localPort,
    this.remote = '',
    this.remotePort = 0,
    this.state = '',
    this.pid = 0,
    this.path = '',
    this.program = '',
  });

  /// tcp | tcp6 | udp | udp6
  final String protocol;
  final String local;
  final int localPort;
  final String remote;
  final int remotePort;

  /// established, listen, time-wait, … ('' for UDP)
  final String state;
  final int pid;

  /// The program file, and its short name ('' when the system does not say).
  final String path;
  final String program;

  Connection withProcess(String path, {String? program}) => Connection(
    protocol: protocol,
    local: local,
    localPort: localPort,
    remote: remote,
    remotePort: remotePort,
    state: state,
    pid: pid,
    path: path,
    program: program ?? programName(path),
  );

  bool get listening => state == 'listen' || (protocol.startsWith('udp') && !hasPeer);

  bool get hasPeer => remote.isNotEmpty && remote != '0.0.0.0' && remote != '::' && remotePort != 0;

  /// Talking to this machine itself.
  bool get loopback => remote.startsWith('127.') || remote == '::1' || remote.startsWith('::ffff:127.');

  /// Talking to the local network rather than the internet.
  bool get lan => isPrivateAddress(remote);
}

/// "C:\\Program Files\\Mozilla Firefox\\firefox.exe" → "firefox",
/// "/usr/lib/firefox/firefox" → "firefox".
String programName(String path) {
  if (path.isEmpty) return '';
  final base = path.split(RegExp(r'[\\/]')).last;
  return base.toLowerCase().endsWith('.exe') ? base.substring(0, base.length - 4) : base;
}

/// RFC 1918, link-local, CGNAT and unique-local addresses.
bool isPrivateAddress(String ip) {
  if (ip.startsWith('::ffff:')) ip = ip.substring(7);
  final v4 = RegExp(r'^(\d+)\.(\d+)\.\d+\.\d+$').firstMatch(ip);
  if (v4 != null) {
    final a = int.parse(v4[1]!), b = int.parse(v4[2]!);
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254) ||
        (a == 100 && b >= 64 && b <= 127);
  }
  final l = ip.toLowerCase();
  return l.startsWith('fe80:') || l.startsWith('fc') || l.startsWith('fd');
}

/// The connections the platform lets an ordinary app see: every one on
/// Linux (programs named only for this user's processes) and Windows;
/// Android has not let apps list sockets since Android 10, so none there.
Future<List<Connection>> readConnections() async {
  if (Platform.isWindows) return windowsConnections();
  if (Platform.isLinux) return linuxConnections();
  return const [];
}

/// Linux: /proc/net/{tcp,tcp6,udp,udp6}, with each socket's inode matched
/// to the process holding it through `/proc/<pid>/fd`. [root] is '' on a real
/// system and a temp dir in tests.
Future<List<Connection>> linuxConnections({String root = ''}) async {
  final owners = await _socketOwners(root);
  final out = <Connection>[];
  for (final protocol in const ['tcp', 'tcp6', 'udp', 'udp6']) {
    final String text;
    try {
      text = await File('$root/proc/net/$protocol').readAsString();
    } on FileSystemException {
      continue;
    }
    for (final row in parseProcNet(text, protocol)) {
      final owner = owners[row.inode];
      out.add(owner == null ? row.connection : row.connection.withProcess(owner.path, program: owner.name));
    }
  }
  return out;
}

const _linuxStates = {
  '01': 'established',
  '02': 'syn-sent',
  '03': 'syn-received',
  '04': 'fin-wait',
  '05': 'fin-wait',
  '06': 'time-wait',
  '07': 'closed',
  '08': 'close-wait',
  '09': 'last-ack',
  '0A': 'listen',
  '0B': 'closing',
};

/// The rows of one /proc/net table, with each socket's inode.
List<({Connection connection, int inode})> parseProcNet(String text, String protocol) {
  final out = <({Connection connection, int inode})>[];
  final udp = protocol.startsWith('udp');
  for (final line in text.split('\n').skip(1)) {
    final f = line.trim().split(RegExp(r'\s+'));
    if (f.length < 10) continue;
    final local = _endpoint(f[1]), remote = _endpoint(f[2]);
    if (local == null || remote == null) continue;
    out.add((
      connection: Connection(
        protocol: protocol,
        local: local.ip,
        localPort: local.port,
        remote: remote.ip,
        remotePort: remote.port,
        state: udp ? '' : (_linuxStates[f[3].toUpperCase()] ?? 'unknown'),
      ),
      inode: int.tryParse(f[9]) ?? 0,
    ));
  }
  return out;
}

/// "0100007F:0035" → 127.0.0.1:53. The kernel prints each 32-bit word of
/// the address in host (little-endian) order.
({String ip, int port})? _endpoint(String text) {
  final parts = text.split(':');
  if (parts.length != 2) return null;
  final port = int.tryParse(parts[1], radix: 16);
  final hex = parts[0];
  if (port == null) return null;
  List<int> word(int i) {
    final w = hex.substring(i * 8, i * 8 + 8);
    return [for (var b = 3; b >= 0; b--) int.parse(w.substring(b * 2, b * 2 + 2), radix: 16)];
  }

  if (hex.length == 8) return (ip: word(0).join('.'), port: port);
  if (hex.length != 32) return null;
  final bytes = [for (var i = 0; i < 4; i++) ...word(i)];
  // An IPv4 address carried in IPv6 (::ffff:a.b.c.d) reads as IPv4.
  if (bytes.take(10).every((b) => b == 0) && bytes[10] == 0xff && bytes[11] == 0xff) {
    return (ip: bytes.skip(12).join('.'), port: port);
  }
  final groups = [for (var i = 0; i < 16; i += 2) ((bytes[i] << 8) | bytes[i + 1]).toRadixString(16)];
  return (ip: groups.join(':').replaceFirst(RegExp(r'(^|:)0(:0)+(:|$)'), '::'), port: port);
}

/// Socket inode → the process holding it, for the processes this user may
/// look into.
Future<Map<int, ({int pid, String name, String path})>> _socketOwners(String root) async {
  final out = <int, ({int pid, String name, String path})>{};
  final List<FileSystemEntity> procs;
  try {
    procs = await Directory('$root/proc').list().toList();
  } on FileSystemException {
    return out;
  }
  for (final p in procs) {
    final pid = int.tryParse(p.path.split('/').last);
    if (pid == null) continue;
    try {
      final fds = await Directory('${p.path}/fd').list().toList();
      String? name, path;
      for (final fd in fds) {
        final String target;
        try {
          target = await Link(fd.path).target();
        } on FileSystemException {
          continue;
        }
        final m = RegExp(r'^socket:\[(\d+)\]$').firstMatch(target);
        if (m == null) continue;
        name ??= (await File('${p.path}/comm').readAsString().catchError((_) => '')).trim();
        path ??= await Link('${p.path}/exe').target().catchError((_) => '');
        out[int.parse(m[1]!)] = (pid: pid, name: name, path: path);
      }
    } on FileSystemException {
      continue; // Another user's process.
    }
  }
  return out;
}

/// Connections grouped by program, busiest first.
class ProgramConnections {
  const ProgramConnections(this.program, this.path, this.connections);
  final String program;
  final String path;
  final List<Connection> connections;

  int get open => connections.where((c) => c.hasPeer).length;
  int get listening => connections.where((c) => c.listening).length;

  /// The distinct remote addresses, most used first.
  List<String> get peers {
    final counts = <String, int>{};
    for (final c in connections.where((c) => c.hasPeer)) {
      counts.update(c.remote, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }
}

List<ProgramConnections> byProgram(List<Connection> all) {
  final groups = <String, List<Connection>>{};
  for (final c in all) {
    groups.putIfAbsent(c.program.isEmpty ? '' : c.program, () => []).add(c);
  }
  final out = [
    for (final e in groups.entries)
      ProgramConnections(
        e.key,
        e.value.firstWhere((c) => c.path.isNotEmpty, orElse: () => e.value.first).path,
        e.value,
      ),
  ];
  out.sort((a, b) {
    final byOpen = b.open.compareTo(a.open);
    return byOpen != 0 ? byOpen : b.connections.length.compareTo(a.connections.length);
  });
  return out;
}
