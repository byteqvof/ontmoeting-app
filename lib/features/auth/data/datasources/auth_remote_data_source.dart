import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';
import '../models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  AuthUserModel? getCurrentUser();

  Stream<AuthUserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
  }) async {
    AppLogger.debug('Supabase auth.signUp started for $email');

    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up completed without a user.');
    }

    AppLogger.debug('Supabase auth.signUp succeeded for ${user.id}');
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.debug('Supabase auth.signInWithPassword started for $email');

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in completed without a user.');
    }

    AppLogger.debug(
      'Supabase auth.signInWithPassword succeeded for ${user.id}',
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() async {
    AppLogger.debug('Supabase auth.signOut started');
    await _client.auth.signOut();
    AppLogger.debug('Supabase auth.signOut succeeded');
  }

  @override
  AuthUserModel? getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AuthUserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      AppLogger.debug(
        'Supabase auth state changed: ${authState.event.name}, '
        'userId: ${user?.id ?? 'none'}',
      );
      if (user == null) {
        return null;
      }
      return AuthUserModel.fromSupabaseUser(user);
    });
  }
}
