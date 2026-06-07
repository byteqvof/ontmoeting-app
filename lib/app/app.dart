import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/di/injection_container.dart';
import '../core/services/push_notification_service.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/home/presentation/widgets/activity_chat_notice_host.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthStarted()),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final _router = createRouter(context.read<AuthBloc>());
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _emailVerificationCallbackSeen = false;

  @override
  void initState() {
    super.initState();
    unawaited(_startEmailVerificationLinkListener());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startEmailVerificationLinkListener() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.debug(
          'Email verification link stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink);
      }
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Initial email verification link lookup failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (!_isEmailVerificationCallback(uri)) {
      return;
    }
    _emailVerificationCallbackSeen = true;
    _goToEmailVerifiedIfAuthenticated(context.read<AuthBloc>().state);
  }

  bool _isEmailVerificationCallback(Uri uri) {
    return uri.scheme == 'meetingsapp' &&
        uri.host == 'auth-callback' &&
        uri.path == '/email-verification';
  }

  void _goToEmailVerifiedIfAuthenticated(AuthState state) {
    if (!_emailVerificationCallbackSeen || state is! AuthAuthenticated) {
      return;
    }
    _emailVerificationCallbackSeen = false;
    _router.go(AppRoutes.emailVerified);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        final push = sl<PushNotificationService>();
        if (state is AuthAuthenticated) {
          unawaited(push.registerForCurrentUser());
          _goToEmailVerifiedIfAuthenticated(state);
        }
        if (state is AuthUnauthenticated) {
          unawaited(push.unregisterCurrentToken());
        }
      },
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) {
          return ActivityChatNoticeHost(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
