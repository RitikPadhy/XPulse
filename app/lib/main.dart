import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

/// Load `.env` (the backend URL — always the deployed host, even locally),
/// then render immediately. [AppShell] does the heavier async startup in
/// initState; doing it here before runApp() would hang the native launch
/// screen on iOS, so main() stays light.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Missing/malformed .env — ApiClient surfaces a clear connection error
    // rather than silently falling back to localhost.
  }
  runApp(const XPulseApp());
}
