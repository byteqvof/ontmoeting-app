import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences(this._preferences);

  static const _initialFtiSeenKey = 'initial_fti_seen';

  final SharedPreferences _preferences;

  bool get hasSeenInitialFti {
    return _preferences.getBool(_initialFtiSeenKey) ?? false;
  }

  Future<void> markInitialFtiSeen() {
    return _preferences.setBool(_initialFtiSeenKey, true);
  }
}
