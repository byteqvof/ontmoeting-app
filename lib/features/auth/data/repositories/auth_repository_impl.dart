import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_oauth_provider.dart';
import '../../domain/entities/auth_sign_up_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, AuthSignUpResult>> signUp({
    required String email,
    required String password,
  }) async {
    return _guardNetworkCall(
      operation: 'signUp',
      () => _remoteDataSource.signUp(email: email, password: password),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    return _guardNetworkCall(
      operation: 'signIn',
      () => _remoteDataSource.signIn(email: email, password: password),
    );
  }

  @override
  Future<Either<Failure, void>> signInWithOAuth(
    AuthOAuthProvider provider,
  ) async {
    return _guardNetworkCall(
      operation: 'signInWithOAuth:${provider.name}',
      () => _remoteDataSource.signInWithOAuth(provider),
    );
  }

  @override
  Future<Either<Failure, void>> resendSignUpVerificationEmail(
    String email,
  ) async {
    return _guardNetworkCall(
      operation: 'resendSignUpVerificationEmail',
      () => _remoteDataSource.resendSignUpVerificationEmail(email),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return _guardNetworkCall(operation: 'signOut', _remoteDataSource.signOut);
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      return right(_remoteDataSource.getCurrentUser());
    } catch (error, stackTrace) {
      AppLogger.debug(
        'AuthRepository.getCurrentUser failed',
        error: error,
        stackTrace: stackTrace,
      );
      return left(_mapExceptionToFailure(error));
    }
  }

  @override
  Stream<Either<Failure, AuthUser?>> authStateChanges() async* {
    try {
      await for (final user in _remoteDataSource.authStateChanges()) {
        yield right(user);
      }
    } catch (error, stackTrace) {
      AppLogger.debug(
        'AuthRepository.authStateChanges failed',
        error: error,
        stackTrace: stackTrace,
      );
      yield left(_mapExceptionToFailure(error));
    }
  }

  Future<Either<Failure, T>> _guardNetworkCall<T>(
    Future<T> Function() action, {
    required String operation,
  }) async {
    AppLogger.debug('AuthRepository.$operation started');

    try {
      final result = await action();
      AppLogger.debug('AuthRepository.$operation succeeded');
      return right(result);
    } catch (error, stackTrace) {
      AppLogger.debug(
        'AuthRepository.$operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      return left(_mapExceptionToFailure(error));
    }
  }

  Failure _mapExceptionToFailure(Object error) {
    AppLogger.debug(
      'Mapping auth exception: ${error.runtimeType}',
      error: error,
    );

    if (error is supabase.AuthRetryableFetchException) {
      return const NetworkFailure('De verbinding hapert. Probeer het opnieuw.');
    }
    if (_looksLikeNetworkPermissionError(error)) {
      return const NetworkFailure('De verbinding hapert. Probeer het opnieuw.');
    }
    if (error is supabase.AuthException) {
      return AuthFailure(_authErrorMessage(error.message));
    }
    if (error is supabase.PostgrestException) {
      return const ServerFailure(
        'Je account bijwerken lukt nu niet. Probeer het later opnieuw.',
      );
    }
    if (error is supabase.StorageException) {
      return const ServerFailure(
        'Je gegevens opslaan lukt nu niet. Probeer het later opnieuw.',
      );
    }
    if (error is supabase.FunctionException) {
      return const ServerFailure(
        'Deze actie lukt nu niet. Probeer het later opnieuw.',
      );
    }
    return const UnknownFailure('Er ging iets mis. Probeer het later opnieuw.');
  }

  bool _looksLikeNetworkPermissionError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('operation not permitted') ||
        message.contains('connection failed') ||
        message.contains('socketexception') ||
        message.contains('clientexception');
  }

  String _authErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid') ||
        normalized.contains('credentials') ||
        normalized.contains('password')) {
      return 'E-mailadres of wachtwoord klopt niet.';
    }
    if (normalized.contains('confirm') || normalized.contains('verified')) {
      return 'Bevestig eerst je e-mailadres.';
    }
    if (normalized.contains('already') || normalized.contains('exists')) {
      return 'Er bestaat al een account met dit e-mailadres.';
    }
    if (normalized.contains('rate') || normalized.contains('too many')) {
      return 'Je hebt dit te vaak geprobeerd. Wacht even en probeer opnieuw.';
    }
    return 'Inloggen of registreren lukt nu niet. Probeer het opnieuw.';
  }
}
