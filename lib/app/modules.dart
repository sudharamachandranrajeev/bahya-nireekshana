import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../ui/connections_page.dart';
import '../ui/firewall_page.dart';
import '../ui/now_page.dart';
import '../ui/plans_page.dart';
import '../ui/speed_page.dart';
import '../ui/themes_page.dart';
import '../ui/usage_page.dart';
import 'settings_page.dart';

Destination _d(
  String id,
  String label,
  IconData icon,
  IconData selected,
  Widget page, {
  bool primary = false,
}) => Destination(
  id: id,
  label: label,
  icon: icon,
  selectedIcon: selected,
  primary: primary,
  page: (_) => page,
);

/// Connections are listed on Linux and Windows; Android has not let apps
/// see sockets since Android 10. The firewall is OpenSnitch on Linux.
final networkModule = AppModule(
  id: 'network',
  name: 'Network',
  destinations: [
    _d('now', 'Now', Icons.radar_outlined, Icons.radar, const NowPage(), primary: true),
    _d('usage', 'Usage', Icons.bar_chart_outlined, Icons.bar_chart, const UsagePage(), primary: true),
    _d('plans', 'Plans', Icons.data_usage_outlined, Icons.data_usage, const PlansPage(), primary: true),
    _d('speed', 'Speed test', Icons.speed_outlined, Icons.speed, const SpeedPage(), primary: true),
    if (Platform.isLinux || Platform.isWindows)
      _d('connections', 'Connections', Icons.cable_outlined, Icons.cable, const ConnectionsPage()),
    if (Platform.isLinux)
      _d('firewall', 'Firewall', Icons.shield_outlined, Icons.shield, const FirewallPage()),
    _d('themes', 'Themes', Icons.palette_outlined, Icons.palette, const ThemesPage()),
  ],
);

final modules = <AppModule>[networkModule];

/// Settings is app-wide, so it comes after every module's screens.
final settingsDestination = _d(
  'settings',
  'Settings',
  Icons.settings_outlined,
  Icons.settings,
  const SettingsPage(),
);

List<Destination> get allDestinations => [for (final m in modules) ...m.destinations, settingsDestination];
