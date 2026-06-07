import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_oauth_provider.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_state_changes.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_oauth.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signIn,
    this._signInWithOAuth,
    this._signUp,
    this._signOut,
    this._getCurrentUser,
    this._authStateChanges,
  ) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthOAuthSignInRequested>(_onOAuthSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthFailureReceived>(_onFailureReceived);
  }

  final SignIn _signIn;
  final SignInWithOAuth _signInWithOAuth;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final AuthStateChanges _authStateChanges;

  StreamSubscription<Either<Failure, AuthUser?>>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final currentUserResult = await _getCurrentUser(const NoParams());
    currentUserResult.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      ),
    );

    await _authSubscription?.cancel();
    _authSubscription = _authStateChanges(const NoParams()).listen((result) {
      result.fold(
        (failure) => add(AuthFailureReceived(failure)),
        (user) => add(AuthUserChanged(user)),
      );
    });
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.debug('AuthBloc sign-in requested for ${event.email}');
    emit(const AuthLoading());
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) {
        AppLogger.debug('AuthBloc sign-in failed: ${failure.message}');
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {'step': 'sign_in', 'status': 'failure'},
        );
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.debug('AuthBloc sign-in authenticated ${user.id}');
        AnalyticsService.instance.identify(user.id);
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {'step': 'sign_in', 'status': 'success'},
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onOAuthSignInRequested(
    AuthOAuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.debug(
      'AuthBloc OAuth sign-in requested for ${event.provider.name}',
    );
    emit(const AuthLoading());
    final result = await _signInWithOAuth(
      SignInWithOAuthParams(event.provider),
    );
    result.fold(
      (failure) {
        AppLogger.debug('AuthBloc OAuth sign-in failed: ${failure.message}');
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {
            'step': 'oauth_sign_in',
            'provider': event.provider.name,
            'status': 'failure',
          },
        );
        emit(AuthError(failure.message));
      },
      (_) {
        AppLogger.debug(
          'AuthBloc OAuth sign-in launched for ${event.provider.name}',
        );
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {
            'step': 'oauth_sign_in',
            'provider': event.provider.name,
            'status': 'launched',
          },
        );
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.debug('AuthBloc sign-up requested for ${event.email}');
    emit(const AuthLoading());
    final result = await _signUp(
      SignUpParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) {
        AppLogger.debug('AuthBloc sign-up failed: ${failure.message}');
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {'step': 'sign_up', 'status': 'failure'},
        );
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.debug('AuthBloc sign-up authenticated ${user.id}');
        AnalyticsService.instance.identify(user.id);
        AnalyticsService.instance.track(
          'registration_funnel',
          properties: {'step': 'sign_up', 'status': 'success'},
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signOut(const NoParams());
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      AnalyticsService.instance.reset();
      emit(const AuthUnauthenticated());
    });
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      AnalyticsService.instance.identify(user.id);
    }
    emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
  }

  void _onFailureReceived(AuthFailureReceived event, Emitter<AuthState> emit) {
    emit(AuthError(event.failure.message));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
