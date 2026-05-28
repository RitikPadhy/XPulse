import 'package:flutter/widgets.dart';

import 'app.dart';

/// Render the Flutter UI immediately, then let [AppShell] do the async startup
/// work (keychain wipe + snapshot fetch) in initState. Doing plugin/network
/// work here BEFORE runApp() hangs the native launch screen on iOS, so we keep
/// main() trivial.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XPulseApp());
}
