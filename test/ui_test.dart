import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nireekshana/app/modules.dart';
import 'package:brahma_core/brahma_core.dart';
import 'package:nireekshana/domain/book.dart';

import 'app_harness.dart';
import 'seed.dart';
import 'support.dart';

/// Smoke tests: every page builds, with and without data, on phone and
/// desktop widths, without throwing or overflowing; and the main flows.
void main() {
  final pages = [for (final d in allDestinations) d.label];

  testWidgets('every page builds on a desktop window, empty and with data', (tester) async {
    for (final seeded in [false, true]) {
      final app = AppHarness(tester)..desktop();
      await app.open(seed: seeded ? seedBook : null);
      await app.run();
      for (final label in pages) {
        await app.go(label);
        expect(tester.takeException(), isNull, reason: '$label (seeded: $seeded)');
      }
      await app.close();
    }
  });

  testWidgets('every page builds on a phone', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedBook);
    await app.run();
    for (final label in pages) {
      await app.go(label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await app.close();
  });

  testWidgets('Now shows live speed and records it as usage', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run();
    // FakeProbe moves 1.2 MB a second down: 9.6 Mbps.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
      await app.settle();
    }
    expect(find.text('9.6 Mbps'), findsWidgets);
    expect(find.textContaining('wlan0'), findsOneWidget);
    // A minute later the recorder writes what it counted.
    for (var i = 0; i < 62; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await app.settle();
    final rows = await tester.runAsync(() => app.book.usageSince('2000-01-01'));
    expect(rows, isNotEmpty);
    expect(rows!.single.kind, 'wifi');
    expect(rows.single.rx, greaterThan(0));
    await app.close();
  });

  testWidgets('a data plan is added and shown', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Plans');
    await app.tapText('Add plan');
    await app.enter('Name', 'Travel SIM');
    await app.enter('Allowance', '5 GB');
    await app.tapText('Save');
    expect(find.text('Travel SIM'), findsOneWidget);
    final plans = await tester.runAsync(() => app.book.plans());
    expect(plans!.map((p) => p.name), contains('Travel SIM'));
    expect(plans.firstWhere((p) => p.name == 'Travel SIM').capBytes, 5 * gb);
    await app.close();
  });

  testWidgets('choosing a theme and making a new one', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run();
    await app.go('Themes');
    await app.tapText('Terminal');
    expect(await tester.runAsync(() => app.session.db.localSetting(LocalKeys.theme)), 'terminal');
    await app.tapText('New theme');
    await app.enter('Name', 'Night shift');
    await app.tapText('Save');
    final mine = await tester.runAsync(() => app.book.themes());
    expect(mine!.single.name, 'Night shift');
    // A new theme is put to use straight away.
    expect(await tester.runAsync(() => app.session.db.localSetting(LocalKeys.theme)), mine.single.id);
    expect(find.text('Yours'), findsOneWidget);
    await app.close();
  });

  testWidgets('the firewall blocks a site through the helper', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run();
    await app.go('Firewall');
    expect(find.text('firefox'), findsOneWidget);
    expect(find.text('ads.example.net'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'tracker.example.org');
    await tester.pump();
    await app.tap(find.widgetWithText(FilledButton, 'Block'));
    expect(app.firewall.changes.single, ['list-add', 'block-domains', 'tracker.example.org']);
    await app.close();
  });

  testWidgets('connections are grouped by program', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open();
    await app.run();
    await app.go('Connections');
    expect(find.text('firefox'), findsOneWidget);
    // Local-network peers and listeners only show under Everything.
    expect(find.text('avahi-daemon'), findsNothing);
    await app.tapText('Everything');
    expect(find.text('avahi-daemon'), findsOneWidget);
    await app.close();
  });

  testWidgets('a usage day can be picked on the chart', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Usage');
    expect(find.text('Last 30 days'), findsOneWidget);
    await app.tapText('Months');
    expect(find.text('Last 12 months'), findsOneWidget);
    expect(find.text('By device'), findsOneWidget);
    expect(find.textContaining('Pixel 9'), findsWidgets);
    await app.close();
  });

  testWidgets('the Apps page ranks apps and opens one', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedBook);
    await app.run();
    await app.go('Apps');
    expect(find.text('Every app'), findsOneWidget);
    expect(find.text('YouTube'), findsWidgets);
    // The phone says what moved in the background; the laptop cannot.
    expect(find.text('Background'), findsOneWidget);
    await app.tapText('Pixel 9');
    expect(find.text('firefox'), findsNothing);
    await app.tapText('Everything');
    await app.tapText('firefox');
    expect(find.text('/usr/lib/firefox/firefox'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Busiest day'), findsOneWidget);
    await app.close();
  });

  testWidgets('usage per app is imported from the system record', (tester) async {
    final app = AppHarness(tester)..desktop();
    final source = FakeAppSource([
      (day: today(), app: '/usr/bin/curl', name: 'curl', kind: 'wifi', rx: 5 * mb, tx: mb, fg: null),
    ]);
    app.appSource = source;
    await app.open();
    await app.run();
    await app.go('Apps');
    expect(source.asked, [31]);
    expect(find.text('curl'), findsWidgets);
    final rows = await tester.runAsync(() => app.book.appsSince('2000-01-01'));
    expect(rows!.single.rx, 5 * mb);
    // Five minutes later it reads only the last two days.
    for (var i = 0; i < 301; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await app.settle();
    expect(source.asked, [31, 2]);
    await app.close();
  });

  testWidgets('the Apps page says when the record needs setting up', (tester) async {
    final app = AppHarness(tester)..desktop();
    app.appSource = FakeAppSource(const [], ready: false);
    await app.open();
    await app.run();
    await app.go('Apps');
    expect(find.text('Apps on this device'), findsOneWidget);
    expect(find.text('No usage per app yet'), findsOneWidget);
    await app.close();
  });
}
