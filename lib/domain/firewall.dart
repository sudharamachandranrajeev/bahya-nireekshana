/// The OpenSnitch firewall on Linux, as the Omarchy setup (omarchy/) leaves
/// it: rules and lists are read from the summary `nireekshana-rules`
/// exports, and changed by running that helper through pkexec. The same
/// logic as the bar widget's (omarchy/plugin/Model.js), so the app and the
/// widget always agree.
library;

import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart' show UserFacingError;

const rulesHelper = '/usr/local/bin/nireekshana-rules';
const rulesExport = '/run/nireekshana/rules.json';

class FirewallException implements Exception, UserFacingError {
  FirewallException(this.message);
  @override
  final String message;
  @override
  String toString() => message;
}

/// The lists: what they hold, what they do, and where "the other way" lives.
const listMeta = {
  'block-domains': (kind: 'site', action: 'block', opposite: 'allow-domains'),
  'allow-domains': (kind: 'site', action: 'allow', opposite: 'block-domains'),
  'block-nets': (kind: 'address', action: 'block', opposite: 'allow-nets'),
  'allow-nets': (kind: 'address', action: 'allow', opposite: 'block-nets'),
};

/// Sections in display order: kind → title.
const ruleSections = {
  'app': 'Apps',
  'site': 'Sites',
  'address': 'IP addresses and networks',
  'other': 'Other rules',
  'system': 'System services set up by Bahya Nireekshana',
};

/// One saved OpenSnitch answer or list entry.
class RuleItem {
  const RuleItem({
    required this.id,
    required this.source,
    required this.action,
    required this.kind,
    required this.title,
    required this.detail,
    this.file = '',
    this.list = '',
    this.enabled = true,
  });

  final String id;

  /// rule | list
  final String source;

  /// allow | block
  final String action;

  /// app | site | address | other | system
  final String kind;
  final String title;
  final String detail;
  final String file;
  final String list;
  final bool enabled;

  bool get blocked => action == 'block';

  /// Helper arguments that turn an allowed row into a blocked one or back.
  List<String> get flipArgs => source == 'rule'
      ? ['set-action', file, action == 'allow' ? 'deny' : 'allow']
      : ['list-add', listMeta[list]!.opposite, title];

  List<String> get deleteArgs => source == 'rule' ? ['delete', file] : ['list-remove', list, title];
}

String _basename(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 || i == path.length - 1 ? path : path.substring(i + 1);
}

String _shorten(String text, int max) => text.length > max ? '${text.substring(0, max - 1)}…' : text;

RuleItem ruleItem(Map rule) {
  final op = rule['operator'] is Map ? rule['operator'] as Map : const {};
  final list = op['list'];
  final conditions = op['type'] == 'list' && list is List && list.isNotEmpty ? list : [op];
  var app = '', appPath = '', destKind = 'site';
  final dests = <String>[], others = <String>[];
  for (final c in conditions.whereType<Map>()) {
    final data = c['data'] == null ? '' : '${c['data']}';
    final pattern = c['type'] == 'regexp' ? ' (pattern)' : '';
    switch (c['operand']) {
      case 'process.path':
        app = '${_basename(data)}$pattern';
        appPath = data;
      case 'process.command':
        if (app.isEmpty) app = '${_shorten(data, 40)}$pattern';
        if (appPath.isEmpty) appPath = data;
      case 'dest.host':
        dests.add('$data$pattern');
      case 'dest.ip' || 'dest.network':
        dests.add('$data$pattern');
        destKind = 'address';
      case 'dest.port':
        others.add('port $data');
      case 'user.id':
        others.add('user $data');
      case 'protocol':
        others.add(data.toUpperCase());
      case final String operand when operand.isNotEmpty:
        others.add(data.isEmpty ? operand : '$operand $data');
    }
  }
  final file = '${rule['file'] ?? ''}';
  final system = RegExp(r'^002-nireekshana-').hasMatch(file);
  final title = [
    app,
    dests.join(', '),
    others.join(' · '),
    '${rule['name'] ?? ''}',
    file,
  ].firstWhere((t) => t.isNotEmpty, orElse: () => '');
  final detail = [
    if (rule['enabled'] == false) 'off',
    if (app.isNotEmpty && dests.isNotEmpty) 'to ${dests.join(', ')}',
    if (others.isNotEmpty && title != others.join(' · ')) others.join(' · '),
    if (appPath.isNotEmpty && appPath != title) appPath,
  ];
  return RuleItem(
    id: 'rule:$file',
    source: 'rule',
    file: file,
    action: rule['action'] == 'allow' ? 'allow' : 'block',
    enabled: rule['enabled'] != false,
    kind: system
        ? 'system'
        : app.isNotEmpty
        ? 'app'
        : dests.isNotEmpty
        ? destKind
        : 'other',
    title: title,
    detail: detail.join(' · '),
  );
}

RuleItem listItem(String listId, String entry) {
  final meta = listMeta[listId]!;
  return RuleItem(
    id: 'list:$listId:$entry',
    source: 'list',
    list: listId,
    action: meta.action,
    kind: meta.kind,
    title: entry,
    detail: meta.action == 'block' ? 'Blocked for every app' : 'Allowed for every app, without asking',
  );
}

/// The helper's export as rows; null when it is missing or unreadable.
({List<RuleItem> items, String generated})? parseRulesExport(String text) {
  final Object? data;
  try {
    data = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (data is! Map) return null;
  final items = <RuleItem>[];
  for (final r in (data['rules'] as List? ?? const []).whereType<Map>()) {
    // 000/001 rules are the lists themselves; their entries come below.
    if (r['error'] != null || RegExp(r'^00[01]-nireekshana-').hasMatch('${r['file'] ?? ''}')) continue;
    items.add(ruleItem(r));
  }
  final lists = data['lists'] is Map ? data['lists'] as Map : const {};
  for (final id in listMeta.keys) {
    for (final e in (lists[id] as List? ?? const [])) {
      items.add(listItem(id, '$e'));
    }
  }
  return (items: items, generated: '${data['generated'] ?? ''}');
}

/// What an "add" field holds: a site or an IP address/network, or why not.
/// The helper checks again; this is the hint while typing.
({String? kind, String value, String error}) classifyEntry(String text) {
  final value = text.trim().toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  if (value.isEmpty) return (kind: null, value: '', error: '');
  if (value.contains('*')) {
    return (kind: null, value: value, error: 'Wildcards are not supported; add each name you want covered.');
  }
  final v4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:/(\d{1,2}))?$').firstMatch(value);
  if (v4 != null) {
    for (var i = 1; i <= 4; i++) {
      if (int.parse(v4[i]!) > 255) return (kind: null, value: value, error: 'Not a valid IP address.');
    }
    final bits = v4[5] == null ? null : int.parse(v4[5]!);
    if (bits != null && (bits < 1 || bits > 32)) {
      return (kind: null, value: value, error: 'Network size must be /1 to /32.');
    }
    return (kind: 'address', value: value, error: '');
  }
  final v6 = RegExp(r'^[0-9a-f:.]*:[0-9a-f:.]*(?:/(\d{1,3}))?$').firstMatch(value);
  if (v6 != null) {
    final bits = v6[1] == null ? null : int.parse(v6[1]!);
    if (bits != null && (bits < 1 || bits > 128)) {
      return (kind: null, value: value, error: 'Network size must be /1 to /128.');
    }
    return (kind: 'address', value: value, error: '');
  }
  if (RegExp(
    r'^(?=.{1,253}$)(?:[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
  ).hasMatch(value)) {
    return (kind: 'site', value: value, error: '');
  }
  return (kind: null, value: value, error: 'Enter a domain like example.com, or an IP address or network.');
}

List<String> addArgs(String kind, String value, {required bool block}) => [
  'list-add',
  '${block ? 'block' : 'allow'}-${kind == 'site' ? 'domains' : 'nets'}',
  value,
];

/// What the firewall side of this machine looks like.
class FirewallStatus {
  const FirewallStatus({required this.helper, required this.export, required this.daemon});
  final bool helper;
  final bool export;

  /// active | inactive | missing
  final String daemon;

  bool get ready => helper && export;
}

/// Reads and changes the rules on this machine. Only Linux has it.
class Firewall {
  const Firewall();

  Future<FirewallStatus> status() async {
    var daemon = 'missing';
    try {
      final r = await Process.run('systemctl', ['is-active', 'opensnitchd.service']);
      final out = '${r.stdout}'.trim();
      daemon = out == 'active' ? 'active' : (out == 'inactive' || out == 'failed' ? 'inactive' : 'missing');
    } on ProcessException {
      daemon = 'missing';
    }
    return FirewallStatus(
      helper: await File(rulesHelper).exists(),
      export: await File(rulesExport).exists(),
      daemon: daemon,
    );
  }

  Future<({List<RuleItem> items, String generated})> rules() async {
    final String text;
    try {
      text = await File(rulesExport).readAsString();
    } on FileSystemException {
      throw FirewallException('The rules summary is missing. Run omarchy/install.sh with sudo to set it up.');
    }
    final parsed = parseRulesExport(text);
    if (parsed == null) throw FirewallException('The rules summary could not be read.');
    return parsed;
  }

  /// Runs the helper through pkexec; the desktop's polkit agent asks for the
  /// password (once every few minutes).
  Future<void> change(List<String> args) async {
    final ProcessResult r;
    try {
      r = await Process.run('pkexec', [rulesHelper, ...args]);
    } on ProcessException {
      throw FirewallException('pkexec is not installed, so rules cannot be changed from here.');
    }
    switch (r.exitCode) {
      case 0:
        return;
      case 126:
        throw FirewallException('Cancelled; nothing was changed.');
      case 127:
        throw FirewallException('Not authorized to change rules.');
      default:
        final text = '${r.stderr}${r.stdout}'.trim();
        throw FirewallException(
          text.isEmpty ? 'The change failed (exit ${r.exitCode}).' : text.split('\n').last,
        );
    }
  }
}
