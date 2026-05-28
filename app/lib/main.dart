import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wipe any stale Keychain entries from a previous install before any
  // widget reads the token. After this, the saved token persists across
  // every app launch until the app is deleted.
  await StorageService.instance.ensureFreshInstallIsClean();
  runApp(const XPulseApp());
}
