import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_oauth_provider.dart';
import '../../domain/entities/auth_sign_up_result.dart';
import '../models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signInWithOAuth(AuthOAuthProvider provider);

  Future<void> resendSignUpVerificationEmail(String email);

  Future<void> signOut();

  AuthUserModel? getCurrentUser();

  Stream<AuthUserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    AppLogger.debug('Supabase auth.signUp started for $email');

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.emailVerificationRedirectTo,
    );

    final user = response.user;
    if (response.session == null) {
      AppLogger.debug('Supabase auth.signUp requires email verification');
      return AuthSignUpEmailVerificationRequired(user?.email ?? email);
    }

    if (user == null) {
      throw const AuthException(
        'Sign up completed with a session but no user.',
      );
    }
    AppLogger.debug('Supabase auth.signUp succeeded for ${user.id}');
    return AuthSignUpAuthenticated(AuthUserModel.fromSupabaseUser(user));
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
  Future<void> signInWithOAuth(AuthOAuthProvider provider) async {
    final supabaseProvider = switch (provider) {
      AuthOAuthProvider.apple => OAuthProvider.apple,
      AuthOAuthProvider.google => OAuthProvider.google,
    };

    AppLogger.debug(
      'Supabase auth.signInWithOAuth started for ${provider.name}',
    );

    final launched = await _client.auth.signInWithOAuth(
      supabaseProvider,
      redirectTo: SupabaseConfig.oauthRedirectTo,
    );

    if (!launched) {
      throw AuthException(
        'Could not open ${provider.name} sign-in. Please try again.',
      );
    }

    AppLogger.debug(
      'Supabase auth.signInWithOAuth launched for ${provider.name}',
    );
  }

  @override
  Future<void> resendSignUpVerificationEmail(String email) async {
    AppLogger.debug('Supabase auth.resend signup verification for $email');
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: SupabaseConfig.emailVerificationRedirectTo,
    );
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
