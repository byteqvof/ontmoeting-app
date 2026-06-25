import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

class SupabaseAuthStorage extends LocalStorage implements GotrueAsyncStorage {
  SupabaseAuthStorage({required this.persistSessionKey});

  final String persistSessionKey;
  Future<SharedPreferences>? _preferences;
  SharedPreferences? _initializedPreferences;

  @override
  Future<void> initialize() async {
    _initializedPreferences = await _timed(
      'SharedPreferences.getInstance',
      _loadPreferences,
    );
  }

  @override
  Future<bool> hasAccessToken() async {
    final prefs = await _prefs();
    return _timed(
      'Supabase auth storage hasAccessToken',
      () async => prefs.containsKey(persistSessionKey),
    );
  }

  @override
  Future<String?> accessToken() async {
    final prefs = await _prefs();
    return _timed(
      'Supabase auth storage accessToken',
      () async => prefs.getString(persistSessionKey),
    );
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await _prefs();
    await _timed(
      'Supabase auth storage removePersistedSession',
      () => prefs.remove(persistSessionKey),
    );
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final prefs = await _prefs();
    await _timed(
      'Supabase auth storage persistSession',
      () => prefs.setString(persistSessionKey, persistSessionString),
    );
  }

  @override
  Future<String?> getItem({required String key}) async {
    final prefs = await _prefs();
    return _timed(
      'Supabase PKCE storage getItem',
      () async => prefs.getString(key),
    );
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    final prefs = await _prefs();
    await _timed(
      'Supabase PKCE storage setItem',
      () => prefs.setString(key, value),
    );
  }

  @override
  Future<void> removeItem({required String key}) async {
    final prefs = await _prefs();
    await _timed('Supabase PKCE storage removeItem', () => prefs.remove(key));
  }

  Future<SharedPreferences> _prefs() {
    final initialized = _initializedPreferences;
    if (initialized != null) {
      return Future.value(initialized);
    }
    return _loadPreferences();
  }

  Future<SharedPreferences> _loadPreferences() {
    return _preferences ??= SharedPreferences.getInstance();
  }

  Future<T> _timed<T>(String name, Future<T> Function() run) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await run();
    } finally {
      AppLogger.debug('$name completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}
