import 'package:brahma_core/brahma_core.dart';

import '../db/database.dart';
import '../domain/book.dart';

/// Bahya Nireekshana in Brahma's terms: the app's id, name and Android
/// package.
const nireekshanaIdentity = AppIdentity(
  id: 'nireekshana',
  name: 'Bahya Nireekshana',
  androidPackage: 'dev.brahma.nireekshana',
  releases: 'sudharamachandranrajeev/bahya-nireekshana',
);

/// Everything a running app needs: keys, the encrypted database and the
/// book on top of it. Opened once at start-up.
class AppSession extends CoreSession {
  AppSession(super.keys, super.store, this.book, {super.deviceName});

  final NetBook book;

  @override
  AppDatabase get db => store.db as AppDatabase;

  static Future<AppSession> open(KeyVault keys) => CoreSession.open(
    nireekshanaIdentity,
    keys,
    openDatabase: AppDatabase.open,
    build: (store, deviceName) =>
        AppSession(keys, store, NetBook(store, deviceName: deviceName), deviceName: deviceName),
  );
}
