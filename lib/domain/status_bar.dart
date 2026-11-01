import 'dart:io';

import 'package:flutter/services.dart';

/// What [StatusBarSpeed.status] reports: whether the speed is on, and the
/// two things that can hide or stop it.
typedef StatusBarFacts = ({bool enabled, bool notifications, bool unrestricted});

/// Android: the live speed as an ongoing notification in the status bar,
/// from a foreground service (android/.../SpeedService.kt) that keeps
/// running with the app closed and comes back after a restart.
class StatusBarSpeed {
  const StatusBarSpeed();

  static const _channel = MethodChannel('dev.brahma.nireekshana/statusbar');

  /// Only Android has it.
  static bool get supported => Platform.isAndroid;

  Future<StatusBarFacts> status() async => _facts(await _channel.invokeMapMethod<String, Object?>('status'));

  /// Turns it on or off; it stays that way across restarts.
  Future<StatusBarFacts> setEnabled(bool on) async =>
      _facts(await _channel.invokeMapMethod<String, Object?>('setEnabled', {'on': on}));

  /// The notification permission prompt, or the app's notification settings
  /// once the prompt can no longer be shown.
  Future<void> askNotifications() => _channel.invokeMethod<void>('askNotifications');

  /// The system's "let the app always run in the background" dialog.
  Future<void> askBattery() => _channel.invokeMethod<void>('askBattery');

  /// The app's page in the system settings (Battery → Unrestricted).
  Future<void> openAppInfo() => _channel.invokeMethod<void>('openAppInfo');

  static StatusBarFacts _facts(Map<String, Object?>? m) => (
    enabled: m?['enabled'] == true,
    notifications: m?['notifications'] == true,
    unrestricted: m?['unrestricted'] == true,
  );
}
