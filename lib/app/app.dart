import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/di/injection_container.dart';
import '../core/services/push_notification_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        final push = sl<PushNotificationService>();
        if (state is AuthAuthenticated) {
          unawaited(push.registerForCurrentUser());
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
