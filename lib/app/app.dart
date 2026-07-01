import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/di/injection_container.dart';
import '../core/services/push_notification_service.dart';
import '../core/utils/activity_deep_links.dart';
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
  StreamSubscription<String>? _pushChatOpenSubscription;
  StreamSubscription<String>? _pushActivityOpenSubscription;
  StreamSubscription<String>? _pushProfileOpenSubscription;
  bool _emailVerificationCallbackSeen = false;
  String? _pendingPushChatActivityId;
  String? _pendingPushActivityId;
  String? _pendingPushProfileId;

  @override
  void initState() {
    super.initState();
    unawaited(_startEmailVerificationLinkListener());
    _startPushNotificationLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _pushChatOpenSubscription?.cancel();
    _pushActivityOpenSubscription?.cancel();
    _pushProfileOpenSubscription?.cancel();
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

    final activityId = activityIdFromActivityDetailDeepLink(uri);
    if (activityId != null && activityId.isNotEmpty) {
      _handlePushActivityOpen(activityId);
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
    _pushChatOpenSubscription = push.chatNotificationOpens.listen((activityId) {
      _handlePushChatOpen(activityId);
    });
    _pushActivityOpenSubscription = push.activityNotificationOpens.listen((
      activityId,
    ) {
      _handlePushActivityOpen(activityId);
    });
    _pushProfileOpenSubscription = push.profileNotificationOpens.listen((
      profileId,
    ) {
      _handlePushProfileOpen(profileId);
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

  void _handlePushActivityOpen(String activityId) {
    final normalizedActivityId = activityId.trim();
    if (normalizedActivityId.isEmpty) {
      return;
    }

    AppLogger.debug('Push activity open requested for $normalizedActivityId');
    _pendingPushActivityId = normalizedActivityId;
    _openPendingPushActivityIfReady(context.read<AuthBloc>().state);
  }

  void _openPendingPushActivityIfReady(AuthState state) {
    final activityId = _pendingPushActivityId;
    if (activityId == null || activityId.isEmpty) {
      return;
    }
    if (state is! AuthAuthenticated) {
      AppLogger.debug('Push activity open waiting for authenticated session');
      return;
    }

    _pendingPushActivityId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      AppLogger.debug('Opening activity from push notification');
      _router.go(AppRoutes.activityDetailPath(activityId));
    });
  }

  void _handlePushProfileOpen(String profileId) {
    final normalizedProfileId = profileId.trim();
    if (normalizedProfileId.isEmpty) {
      return;
    }

    AppLogger.debug('Push profile open requested for $normalizedProfileId');
    _pendingPushProfileId = normalizedProfileId;
    _openPendingPushProfileIfReady(context.read<AuthBloc>().state);
  }

  void _openPendingPushProfileIfReady(AuthState state) {
    final profileId = _pendingPushProfileId;
    if (profileId == null || profileId.isEmpty) {
      return;
    }
    if (state is! AuthAuthenticated) {
      AppLogger.debug('Push profile open waiting for authenticated session');
      return;
    }

    _pendingPushProfileId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      AppLogger.debug('Opening profile from push notification');
      _router.go(AppRoutes.profilePath(profileId));
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
          unawaited(push.registerForCurrentUserIfPermissionAlreadyGranted());
          _goToEmailVerifiedIfAuthenticated(state);
          _openPendingPushChatIfReady(state);
          _openPendingPushActivityIfReady(state);
          _openPendingPushProfileIfReady(state);
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
