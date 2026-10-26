import 'dart:io';

import 'package:flutter/services.dart';

import 'counters.dart';
import 'windows_net.dart';

/// Reads this device's interface counters. Each platform has its own
/// source; none needs special rights.
abstract class NetProbe {
  Future<Sample> sample();

  /// The probe for the platform this runs on, or null where there is none.
  static NetProbe? forPlatform() {
    if (Platform.isLinux) return LinuxProbe();
    if (Platform.isAndroid) return AndroidProbe();
    if (Platform.isWindows) return WindowsProbe();
    return null;
  }
}

/// Linux: /proc/net/dev for the counters, /sys/class/net for what each
/// interface is. [root] is '' on a real system and a temp dir in tests.
class LinuxProbe implements NetProbe {
  LinuxProbe({this.root = ''});
  final String root;

  @override
  Future<Sample> sample() async {
    final at = DateTime.now();
    final text = await File('$root/proc/net/dev').readAsString();
    final boot = await _read('$root/proc/sys/kernel/random/boot_id');
    final ifaces = <Iface>[];
    for (final c in parseNetDev(text)) {
      final dir = '$root/sys/class/net/${c.name}';
      final kind = linuxKind(
        c.name,
        physical: await Directory('$dir/device').exists(),
        wireless: await Directory('$dir/wireless').exists() || await Link('$dir/phy80211').exists(),
      );
      if (kind == 'loopback') continue;
      final state = await _read('$dir/operstate');
      ifaces.add(
        Iface(name: c.name, kind: kind, rx: c.rx, tx: c.tx, up: state == 'up' || state == 'unknown'),
      );
    }
    return Sample(at, ifaces, boot: boot);
  }

  Future<String> _read(String path) async {
    try {
      return (await File(path).readAsString()).trim();
    } on FileSystemException {
      return '';
    }
  }
}

/// /proc/net/dev's rows: name, received bytes (field 1) and sent bytes
/// (field 9).
List<({String name, int rx, int tx})> parseNetDev(String text) => [
  for (final line in text.split('\n'))
    if (line.indexOf(':') case final colon when colon > 0)
      if (line.substring(colon + 1).trim().split(RegExp(r'\s+')) case final f when f.length >= 9)
        (name: line.substring(0, colon).trim(), rx: int.tryParse(f[0]) ?? 0, tx: int.tryParse(f[8]) ?? 0),
];

/// Android: TrafficStats through MainActivity.kt. It counts per device, not
/// per interface, so this reports two links: mobile data and the rest
/// (Wi-Fi, Ethernet and tethering).
class AndroidProbe implements NetProbe {
  static const channel = MethodChannel('dev.brahma.nireekshana/net');

  @override
  Future<Sample> sample() async {
    final m = await channel.invokeMapMethod<String, Object?>('counters') ?? const {};
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    final mobileRx = n('mobileRx'), mobileTx = n('mobileTx');
    return Sample(DateTime.now(), [
      Iface(
        name: 'wifi',
        label: 'Wi-Fi',
        kind: 'wifi',
        rx: (n('totalRx') - mobileRx).clamp(0, 1 << 62),
        tx: (n('totalTx') - mobileTx).clamp(0, 1 << 62),
      ),
      Iface(name: 'mobile', label: 'Mobile data', kind: 'mobile', rx: mobileRx, tx: mobileTx),
    ], boot: '${m['boot'] ?? ''}');
  }
}

/// Windows: the IP Helper interface table (GetIfTable2), hardware links only.
class WindowsProbe implements NetProbe {
  @override
  Future<Sample> sample() async => Sample(DateTime.now(), windowsInterfaces(), boot: windowsBootId());
}
