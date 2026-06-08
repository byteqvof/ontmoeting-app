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
  StreamSubscription<String>? _pushOpenSubscription;
  bool _emailVerificationCallbackSeen = false;
  String? _pendingPushChatActivityId;

  @override
  void initState() {
    super.initState();
    unawaited(_startEmailVerificationLinkListener());
    _startPushNotificationLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _pushOpenSubscription?.cancel();
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
    if (_isActivityChatLink(uri)) {
      final activityId = _activityChatIdFromLink(uri);
      if (activityId != null && activityId.isNotEmpty) {
        _handlePushChatOpen(activityId);
      }
      return;
    }

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

  bool _isActivityChatLink(Uri uri) {
    return uri.scheme == 'meetingsapp' && uri.host == 'activity-chat';
  }

  String? _activityChatIdFromLink(Uri uri) {
    final fromQuery = uri.queryParameters['activity_id']?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }
    final fromPath = uri.pathSegments.isEmpty
        ? null
        : uri.pathSegments.first.trim();
    if (fromPath != null && fromPath.isNotEmpty) {
      return fromPath;
    }
    return null;
  }

  void _goToEmailVerifiedIfAuthenticated(AuthState state) {
    if (!_emailVerificationCallbackSeen || state is! AuthAuthenticated) {
      return;
    }
    _emailVerificationCallbackSeen = false;
    _router.go(AppRoutes.emailVerified);
  }

  void _startPushNotificationLinkListener() {
    final push = sl<PushNotificationService>();
    _pushOpenSubscription = push.chatNotificationOpens.listen((activityId) {
      _handlePushChatOpen(activityId);
    });
    unawaited(push.startInteractionHandlers());
  }

  void _handlePushChatOpen(String activityId) {
    final normalizedActivityId = activityId.trim();
    if (normalizedActivityId.isEmpty) {
      return;
    }

    AppLogger.debug('Push chat open requested for $normalizedActivityId');
    _pendingPushChatActivityId = normalizedActivityId;
    _openPendingPushChatIfReady(context.read<AuthBloc>().state);
  }

  void _openPendingPushChatIfReady(AuthState state) {
    final activityId = _pendingPushChatActivityId;
    if (activityId == null || activityId.isEmpty) {
      return;
    }
    if (state is! AuthAuthenticated) {
      AppLogger.debug('Push chat open waiting for authenticated session');
      return;
    }

    _pendingPushChatActivityId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      AppLogger.debug('Opening chat from push notification');
      _router.go(AppRoutes.activityChatPath(activityId, from: 'push'));
    });
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
          _openPendingPushChatIfReady(state);
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
