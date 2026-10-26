/// The system's record of how much each app used the network, by day:
/// Android's network statistics per app, the nireekshana-apps counter on
/// Linux (omarchy/bin/nireekshana-apps, over nethogs) and Windows' data
/// usage per app.
library;

import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';

import 'probe.dart';

/// One app's usage on one day over one kind of network, ready to write.
/// [fg] is the part (both ways) moved while the app was on screen, where
/// the system says.
typedef AppCount = ({String day, String app, String name, String kind, int rx, int tx, int? fg});

/// Why per-app usage cannot be read, worded for the user.
class AppSourceException implements Exception {
  AppSourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A system record of each app's usage this device can import.
abstract class AppSource {
  String get title;

  /// Whether it can be read now (set up, permitted).
  Future<bool> available();

  /// Per-app totals for the last [days] days, today included.
  Future<List<AppCount>> read({int days = 31});

  static AppSource? forPlatform() {
    if (Platform.isAndroid) return AndroidAppSource();
    if (Platform.isLinux) return LinuxAppSource();
    if (Platform.isWindows) return WindowsAppSource();
    return null;
  }
}

/// Sums rows that share a day, app and kind (Windows reports each network
/// profile separately; several can be Wi-Fi).
List<AppCount> mergeAppCounts(Iterable<AppCount> rows) {
  final out = <String, AppCount>{};
  for (final r in rows) {
    if (r.rx == 0 && r.tx == 0) continue;
    final key = '${r.day}|${r.kind}|${r.app}';
    final had = out[key];
    out[key] = had == null
        ? r
        : (
            day: r.day,
            app: r.app,
            name: had.name.isEmpty ? r.name : had.name,
            kind: r.kind,
            rx: had.rx + r.rx,
            tx: had.tx + r.tx,
            fg: had.fg == null && r.fg == null ? null : (had.fg ?? 0) + (r.fg ?? 0),
          );
  }
  return out.values.toList();
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Android: NetworkStatsManager per app, through NetStats.kt. Needs usage
/// access, like the device's own history.
class AndroidAppSource implements AppSource {
  @override
  String get title => 'Android network statistics';

  @override
  Future<bool> available() async => await AndroidProbe.channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  @override
  Future<List<AppCount>> read({int days = 31}) async {
    final list = await AndroidProbe.channel.invokeListMethod<Map>('appUsage', {'days': days}) ?? const [];
    return mergeAppCounts([
      for (final m in list)
        (
          day: '${m['day']}',
          app: '${m['app']}',
          name: '${m['name'] ?? m['app']}',
          kind: '${m['kind']}',
          rx: _int(m['rx']),
          tx: _int(m['tx']),
          fg: m['fg'] == null ? null : _int(m['fg']),
        ),
    ]);
  }
}

/// Linux: the file the nireekshana-apps service writes (see
/// omarchy/install.sh, which sets it up).
class LinuxAppSource implements AppSource {
  LinuxAppSource({this.path = '/var/lib/nireekshana/apps.json'});
  final String path;

  @override
  String get title => 'nireekshana-apps';

  @override
  Future<bool> available() => File(path).exists();

  @override
  Future<List<AppCount>> read({int days = 31}) async =>
      parseCollectorApps(await File(path).readAsString(), from: addDays(today(), -(days - 1)));
}

/// The nireekshana-apps file as rows, from day [from] on.
List<AppCount> parseCollectorApps(String json, {String from = ''}) {
  final root = jsonDecode(json);
  if (root is! Map || root['version'] != 1) throw const FormatException('Not a nireekshana-apps file');
  final days = root['days'];
  return mergeAppCounts([
    if (days is Map)
      for (final MapEntry(key: day, value: rows) in days.entries)
        if ('$day'.compareTo(from) >= 0 && rows is List)
          for (final r in rows.whereType<Map>())
            (
              day: '$day',
              app: '${r['app']}',
              name: '${r['name'] ?? r['app']}',
              kind: '${r['kind'] ?? 'other'}',
              rx: _int(r['rx']),
              tx: _int(r['tx']),
              fg: null,
            ),
  ]);
}

/// Windows: the data usage Settings shows, from WinRT's
/// ConnectionProfile.GetAttributedNetworkUsageAsync, through Windows
/// PowerShell 5 (PowerShell 7 cannot reach WinRT).
class WindowsAppSource implements AppSource {
  @override
  String get title => 'Windows data usage';

  @override
  Future<bool> available() async => true;

  @override
  Future<List<AppCount>> read({int days = 31}) async {
    final script = windowsAppScript.replaceFirst('__DAYS__', '${days.clamp(1, 60)}');
    final units = <int>[];
    for (final c in script.codeUnits) {
      units
        ..add(c & 0xff)
        ..add(c >> 8);
    }
    final ProcessResult r;
    try {
      r = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-EncodedCommand',
        base64.encode(units),
      ]);
    } on ProcessException {
      throw AppSourceException('Windows PowerShell is not available.');
    }
    if (r.exitCode != 0) {
      final why = '${r.stderr}'.trim().split('\n').first;
      throw AppSourceException('Windows did not give the usage per app: $why');
    }
    return parseWindowsApps('${r.stdout}');
  }
}

/// The PowerShell script's JSON as rows.
List<AppCount> parseWindowsApps(String json) {
  final text = json.trim();
  if (text.isEmpty) return const [];
  final root = jsonDecode(text);
  final list = root is List ? root : [root];
  return mergeAppCounts([
    for (final r in list.whereType<Map>())
      (
        day: '${r['day']}',
        app: '${r['app']}',
        name: _windowsName('${r['name'] ?? ''}', '${r['app']}'),
        kind: '${r['kind'] ?? 'other'}',
        rx: _int(r['rx']),
        tx: _int(r['tx']),
        fg: null,
      ),
  ]);
}

/// Windows names desktop programs by path; show the file name.
String _windowsName(String name, String app) {
  final n = name.isNotEmpty ? name : app;
  final base = n.split(RegExp(r'[\\/]')).last;
  return base.isEmpty ? n : base;
}

/// Prints JSON rows (day, app, name, kind, rx, tx) for the last __DAYS__
/// days, every connection profile, one query per profile and day.
const windowsAppScript = r'''
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
$null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]
$null = [Windows.Networking.Connectivity.AttributedNetworkUsage, Windows.Networking.Connectivity, ContentType = WindowsRuntime]
$listType = [System.Collections.Generic.IReadOnlyList[Windows.Networking.Connectivity.AttributedNetworkUsage]]
$await = $asTask.MakeGenericMethod($listType)
$states = New-Object Windows.Networking.Connectivity.NetworkUsageStates
$states.Roaming = [Windows.Networking.Connectivity.TriStates]::DoNotCare
$states.Shared = [Windows.Networking.Connectivity.TriStates]::DoNotCare
$inv = [Globalization.CultureInfo]::InvariantCulture
$days = __DAYS__
$today = [DateTime]::Today
$out = New-Object System.Collections.ArrayList
foreach ($p in [Windows.Networking.Connectivity.NetworkInformation]::GetConnectionProfiles()) {
  $kind = if ($p.IsWlanConnectionProfile) { 'wifi' } elseif ($p.IsWwanConnectionProfile) { 'mobile' } else { 'ethernet' }
  for ($i = $days - 1; $i -ge 0; $i--) {
    $start = $today.AddDays(-$i)
    $task = $await.Invoke($null, @($p.GetAttributedNetworkUsageAsync([DateTimeOffset]$start, [DateTimeOffset]$start.AddDays(1), $states)))
    $null = $task.Wait(-1)
    foreach ($u in $task.Result) {
      if ($u.BytesReceived -eq 0 -and $u.BytesSent -eq 0) { continue }
      $null = $out.Add([ordered]@{
        day = $start.ToString('yyyy-MM-dd', $inv); app = $u.AttributionId; name = $u.AttributionName
        kind = $kind; rx = $u.BytesReceived; tx = $u.BytesSent
      })
    }
  }
}
ConvertTo-Json -InputObject @($out) -Compress -Depth 3
''';
