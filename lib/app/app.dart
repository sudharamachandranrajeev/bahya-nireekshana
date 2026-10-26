import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/look.dart';
import 'live.dart';
import 'modules.dart';
import 'providers.dart';
import 'settings_page.dart';

/// The theme the user chose, in [b]; Radar until the list has loaded.
ThemeData chosenTheme(WidgetRef ref, Brightness b) =>
    nirTheme(ref.watch(appearanceProvider).value?.theme ?? fallbackTheme, b);

ThemeMode chosenMode(WidgetRef ref) => ref.watch(appearanceProvider).value?.mode ?? ThemeMode.system;

class NireekshanaApp extends ConsumerWidget {
  const NireekshanaApp({super.key, this.home = const _Root()});
  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Bahya Nireekshana',
    debugShowCheckedModeBanner: false,
    theme: chosenTheme(ref, Brightness.light),
    darkTheme: chosenTheme(ref, Brightness.dark),
    themeMode: chosenMode(ref),
    builder: (context, child) => AppLockGate(child: Backdrop(child: child ?? const SizedBox.shrink())),
    home: home,
  );
}

/// The app, opening the links the platform hands over (a scanned pairing
/// code), and offering a new version at start when there is one.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate().ignore());
  }

  Future<void> _offerUpdate() async {
    final updater = ref.read(updaterProvider);
    if (updater == null) return;
    final release = await ref.read(updateProvider.future).catchError((_) => null);
    if (release != null && mounted) await offerUpdate(context, updater, release);
  }

  @override
  Widget build(BuildContext context) => const LinkHandler(child: NireekshanaHome());
}

/// Bahya Nireekshana's screens. There is no onboarding: Now starts
/// measuring at once. [onHome] leads back to the Brahma suite's home
/// screen when the suite hosts the app.
class NireekshanaHome extends StatelessWidget {
  const NireekshanaHome({super.key, this.onHome});
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) => AppShell(
    destinations: allDestinations,
    floating: true,
    onHome: onHome,
    // Counting starts with the app, whichever page opens first.
    onStart: (ref) => Future.microtask(() => ref.read(liveProvider)).ignore(),
  );
}
