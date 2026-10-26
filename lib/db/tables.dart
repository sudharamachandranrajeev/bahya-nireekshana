import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

// Table names are unique across the Brahma suite: every app on an account
// reads the same change log and applies only its own tables. Bahya
// Nireekshana's all start with `nir_`. Days are yyyy-MM-dd in local time;
// byte counts are whole bytes.
//
// Each device writes only rows it measured (ids start with its device id),
// so two devices never edit the same row and sync never has to merge counts.

/// Data one device moved on one day over one kind of network.
@DataClassName('DayUsage')
class NirDays extends Table with SyncedRow {
  /// The measuring device's id (Store.deviceId) and the name it had then.
  TextColumn get device => text()();
  TextColumn get deviceName => text().withDefault(const Constant(''))();
  TextColumn get day => text()();

  /// wifi | ethernet | mobile | other
  TextColumn get kind => text()();
  IntColumn get rx => integer().withDefault(const Constant(0))();
  IntColumn get tx => integer().withDefault(const Constant(0))();

  /// Where the numbers come from: recorder (this app, while it runs),
  /// vnstat (Linux) or android (the system's network statistics).
  TextColumn get source => text().withDefault(const Constant('recorder'))();
}

/// Data one program moved on one device on one day over one kind of
/// network, from the system's per-app record (see lib/domain/apps.dart).
@DataClassName('AppUsage')
class NirApps extends Table with SyncedRow {
  TextColumn get device => text()();
  TextColumn get deviceName => text().withDefault(const Constant(''))();
  TextColumn get day => text()();

  /// What the system knows the program by: an Android package name, a
  /// program's path on Linux, a Windows attribution id, or `uid:<n>` and
  /// the like for traffic no single app owns.
  TextColumn get app => text()();
  TextColumn get name => text()();

  /// wifi | ethernet | mobile | other
  TextColumn get kind => text()();
  IntColumn get rx => integer().withDefault(const Constant(0))();
  IntColumn get tx => integer().withDefault(const Constant(0))();

  /// Bytes (both ways) moved while the app was on screen; null where the
  /// system does not say (only Android does).
  IntColumn get fg => integer().nullable()();
}

/// A data allowance to watch, e.g. 30 GB of mobile data a month.
@DataClassName('DataPlan')
class NirPlans extends Table with SyncedRow {
  TextColumn get name => text()();
  IntColumn get capBytes => integer()();

  /// Day of the month the allowance starts again, 1 to 28.
  IntColumn get cycleDay => integer().withDefault(const Constant(1))();

  /// Which traffic counts: all | mobile | wifi | ethernet
  TextColumn get kinds => text().withDefault(const Constant('all'))();

  /// The device it applies to, or '' for every device on the account.
  TextColumn get device => text().withDefault(const Constant(''))();

  /// Warn once this share of the allowance is used, 1 to 100.
  IntColumn get warnPercent => integer().withDefault(const Constant(80))();
  TextColumn get created => text()();
}

/// One speed test.
@DataClassName('SpeedTest')
class NirSpeedTests extends Table with SyncedRow {
  TextColumn get device => text()();
  TextColumn get deviceName => text().withDefault(const Constant(''))();

  /// When it ran, ISO 8601 UTC.
  TextColumn get at => text()();

  /// Bits per second.
  IntColumn get down => integer()();
  IntColumn get up => integer()();

  /// Round trip and its spread, in milliseconds.
  RealColumn get latency => real()();
  RealColumn get jitter => real().withDefault(const Constant(0))();

  /// What the device was on: wifi | ethernet | mobile | other
  TextColumn get kind => text().withDefault(const Constant('other'))();
  TextColumn get server => text().withDefault(const Constant(''))();
}

/// A theme made in the theme manager, stored as its export JSON.
@DataClassName('ThemeRow')
class NirThemes extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get json => text()();
  TextColumn get updated => text()();
}

@DataClassName('Pref')
class Prefs extends Table with SyncedRow, PrefColumns {}

@DataClassName('OutboxItem')
class Outbox extends Table with OutboxColumns {}

@DataClassName('SyncCursor')
class SyncCursors extends Table with SyncCursorColumns {}

@DataClassName('LocalSetting')
class LocalSettings extends Table with LocalSettingColumns {}
