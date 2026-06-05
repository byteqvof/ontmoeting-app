import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();
  await configureDependencies();

  runApp(const App());
}
