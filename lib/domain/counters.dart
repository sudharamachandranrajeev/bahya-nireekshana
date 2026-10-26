/// Network interfaces, their byte counters, and turning two readings into
/// speeds and usage. Platform readers live in probe.dart.
library;

/// The kinds of link a day's usage is split by.
const usageKinds = ['wifi', 'ethernet', 'mobile', 'other'];

String kindLabel(String kind) => switch (kind) {
  'wifi' => 'Wi-Fi',
  'ethernet' => 'Ethernet',
  'mobile' => 'Mobile data',
  'vpn' => 'VPN',
  'virtual' => 'Virtual',
  _ => 'Other',
};

/// One interface's counters at one moment. Counters are bytes since the
/// interface (or the device) started.
class Iface {
  const Iface({
    required this.name,
    required this.kind,
    required this.rx,
    required this.tx,
    this.label = '',
    this.up = true,
  });

  /// The system's name (wlan0, "Wi-Fi", …) and a friendlier one if it has one.
  final String name;
  final String label;

  /// wifi | ethernet | mobile | other count towards usage; vpn and virtual
  /// links carry traffic the real ones also carry, so they are shown but
  /// never added in.
  final String kind;
  final int rx;
  final int tx;
  final bool up;

  bool get counted => kind == 'wifi' || kind == 'ethernet' || kind == 'mobile' || kind == 'other';

  String get title => label.isEmpty ? name : label;
}

/// Every interface at one moment, and the boot it belongs to (counters
/// restart with the device, so readings from different boots never
/// subtract).
class Sample {
  const Sample(this.at, this.ifaces, {this.boot = ''});
  final DateTime at;
  final List<Iface> ifaces;
  final String boot;

  int get rx => ifaces.where((i) => i.counted).fold(0, (s, i) => s + i.rx);
  int get tx => ifaces.where((i) => i.counted).fold(0, (s, i) => s + i.tx);
}

/// Linux's interface kind, as the bar widget decides it (Model.js): a
/// wireless device is Wi-Fi, tunnels are VPN, ww* is mobile, anything else
/// with a hardware device is Ethernet, the rest is virtual.
String linuxKind(String name, {required bool physical, required bool wireless}) {
  if (name == 'lo') return 'loopback';
  if (wireless) return 'wifi';
  if (RegExp(r'^(tun|tap|wg|tailscale|zt|ppp|proton|nordlynx|mullvad)').hasMatch(name)) return 'vpn';
  if (name.startsWith('ww')) return 'mobile';
  if (physical) return 'ethernet';
  return 'virtual';
}

/// The bytes moved between two readings, by usage kind. A counter that went
/// down was reset (the link came back, or the device restarted), so all it
/// holds now is new; a reading from another boot counts as a fresh start.
Map<String, ({int rx, int tx})> usageBetween(Sample before, Sample after) {
  final out = <String, ({int rx, int tx})>{};
  final old = {for (final i in before.ifaces) i.name: i};
  final sameBoot = before.boot.isEmpty || before.boot == after.boot;
  for (final i in after.ifaces) {
    if (!i.counted) continue;
    final o = sameBoot ? old[i.name] : null;
    final rx = o == null ? 0 : (i.rx >= o.rx ? i.rx - o.rx : i.rx);
    final tx = o == null ? 0 : (i.tx >= o.tx ? i.tx - o.tx : i.tx);
    if (rx == 0 && tx == 0) continue;
    final kind = usageKinds.contains(i.kind) ? i.kind : 'other';
    final had = out[kind] ?? (rx: 0, tx: 0);
    out[kind] = (rx: had.rx + rx, tx: had.tx + tx);
  }
  return out;
}

/// Speeds between two readings, in bytes per second, per interface (by
/// name) and in total over the counted ones.
class Rates {
  const Rates(this.rx, this.tx, this.byIface);
  final double rx;
  final double tx;
  final Map<String, ({double rx, double tx})> byIface;

  static const zero = Rates(0, 0, {});

  factory Rates.between(Sample before, Sample after) {
    final seconds = after.at.difference(before.at).inMicroseconds / 1e6;
    if (seconds <= 0 || (before.boot.isNotEmpty && before.boot != after.boot)) return zero;
    final old = {for (final i in before.ifaces) i.name: i};
    final by = <String, ({double rx, double tx})>{};
    var rx = 0.0, tx = 0.0;
    for (final i in after.ifaces) {
      final o = old[i.name];
      if (o == null) continue;
      final r = i.rx >= o.rx ? (i.rx - o.rx) / seconds : 0.0;
      final t = i.tx >= o.tx ? (i.tx - o.tx) / seconds : 0.0;
      by[i.name] = (rx: r, tx: t);
      if (i.counted) {
        rx += r;
        tx += t;
      }
    }
    return Rates(rx, tx, by);
  }
}
