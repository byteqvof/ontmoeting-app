import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[App] $message');
    if (error != null) {
      debugPrint('[App] error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[App] stackTrace: $stackTrace');
    }
  }
}
