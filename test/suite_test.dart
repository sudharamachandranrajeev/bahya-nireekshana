import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nireekshana/app/providers.dart';
import 'package:nireekshana/app/session.dart';
import 'package:nireekshana/domain/book.dart';
import 'package:nireekshana/suite.dart';

import 'seed.dart';
import 'support.dart';

void main() {
  testWidgets("the suite card shows today's usage with only the suite overrides", (tester) async {
    late AppSession session;
    await tester.runAsync(() async {
      final store = await Store.open(memoryDatabase());
      session = AppSession(KeyVault(MemorySecretStore(), nireekshanaIdentity), store, NetBook(store));
      await seedBook(session.book);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coreSessionProvider.overrideWithValue(session),
          appIdentityProvider.overrideWithValue(nireekshanaSuite.identity),
          ...nireekshanaSuite.overrides(session),
          // The device itself, faked so the test reads no real counters.
          probeProvider.overrideWithValue(FakeProbe()),
          usageSourceProvider.overrideWithValue(null),
          appSourceProvider.overrideWithValue(null),
        ],
        retry: (_, _) => null,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: nireekshanaSuite.theme(ref, Brightness.light),
            home: Scaffold(body: Builder(builder: nireekshanaSuite.summary)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('today'), findsOneWidget);
    expect(find.text('left of Phone data'), findsOneWidget);
    expect(find.text('↓ 9.6 Mbps'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => session.db.close());
  });
}
