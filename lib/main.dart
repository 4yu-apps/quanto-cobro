import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Local-first: roda 100% offline, sem login. Firebase (Analytics/Crashlytics
  // opt-in), Drift e billing entram nas próximas etapas (ver planning/06).
  runApp(const ProviderScope(child: QuantoCobroApp()));
}
