import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nireekshana/app/app.dart';

import 'app_harness.dart';
import 'seed.dart';

/// Renders the main pages with the real fonts to PNG files, for checking
/// the look and for the README. Runs only when NIREEKSHANA_SHOTS names an
/// output folder:
/// `NIREEKSHANA_SHOTS=/tmp/shots flutter test test/screenshots_test.dart`.
void main() {
  final out = Platform.environment['NIREEKSHANA_SHOTS'];

  Future<void> loadFonts() async {
    Future<void> family(String name, List<String> files) async {
      final loader = FontLoader(name);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
      }
      await loader.load();
    }

    await family('Inter', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf',
    ]);
    await family('PlusJakartaSans', [
      for (final w in ['Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/PlusJakartaSans-$w.ttf',
    ]);
    // The Terminal theme's monospace font.
    const mono = '/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf';
    if (File(mono).existsSync()) await family('monospace', [mono]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
  }

  testWidgets('screenshots', skip: out == null, (tester) async {
    await tester.runAsync(loadFonts);
    // Tests draw elevation as black outlines unless told otherwise.
    debugDisableShadows = false;
    final key = GlobalKey();
    var n = 0;

    Future<void> shot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/${(++n).toString().padLeft(2, '0')}-$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    Widget app(AppHarness h) => RepaintBoundary(
      key: key,
      child: ProviderScope(overrides: h.overrides, retry: (_, _) => null, child: const NireekshanaApp()),
    );

    /// A minute of live readings, so the gauges and chart have something.
    Future<void> warm(AppHarness h) async {
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await h.settle();
    }

    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      final h = AppHarness(tester);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      await h.open(seed: seedBook);
      await tester.pumpWidget(app(h));
      await warm(h);
      final mode = dark ? 'dark' : 'light';
      await shot('now-$mode');
      if (!dark) {
        for (final page in ['Usage', 'Plans', 'Speed test', 'Themes']) {
          await h.go(page);
          await shot('${page.toLowerCase().replaceAll(' ', '-')}-$mode');
        }
      }
      await h.close();
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    tester.view.reset();

    final h = AppHarness(tester)..desktop();
    await h.open(seed: seedBook);
    await tester.pumpWidget(app(h));
    await warm(h);
    await shot('now-desktop');
    await h.go('Usage');
    await shot('usage-desktop');
    await h.go('Connections');
    await shot('connections-desktop');
    await h.go('Firewall');
    await shot('firewall-desktop');
    // Another theme, to show what the manager changes.
    await h.go('Themes');
    await h.tapText('Saffron');
    await shot('themes-desktop');
    await h.close();
    debugDisableShadows = true;
  });
}
