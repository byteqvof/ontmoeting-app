import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/get_activity_detail.dart';
import 'activity_chat_page.dart';
import 'activity_detail_page.dart';

enum ActivityRouteTarget { detail, chat }

class ActivityRouteLoaderPage extends StatefulWidget {
  const ActivityRouteLoaderPage({
    required this.activityId,
    required this.target,
    super.key,
  });

  final String activityId;
  final ActivityRouteTarget target;

  @override
  State<ActivityRouteLoaderPage> createState() =>
      _ActivityRouteLoaderPageState();
}

class _ActivityRouteLoaderPageState extends State<ActivityRouteLoaderPage> {
  final GetActivityDetail _getActivityDetail = sl();

  HomeActivity? _activity;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadActivity());
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getActivityDetail(
      GetActivityDetailParams(widget.activityId),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (activity) {
        setState(() {
          _activity = activity;
          _isLoading = false;
          _errorMessage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    if (activity != null) {
      return switch (widget.target) {
        ActivityRouteTarget.detail => ActivityDetailPage(activity: activity),
        ActivityRouteTarget.chat => ActivityChatPage(activity: activity),
      };
    }

    final title = widget.target == ActivityRouteTarget.chat
        ? 'Chat laden'
        : 'Activiteit laden';

    return Scaffold(
      backgroundColor: context.toch.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.xl),
            child: _isLoading
                ? _RouteLoading(title: title)
                : _RouteError(
                    message:
                        _errorMessage ??
                        'Deze activiteit kan nu niet worden geopend.',
                    onRetry: _loadActivity,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(
                        widget.target == ActivityRouteTarget.chat
                            ? AppRoutes.activityMessages
                            : AppRoutes.home,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _RouteLoading extends StatelessWidget {
  const _RouteLoading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: context.toch.green),
        const SizedBox(height: TochSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _RouteError extends StatelessWidget {
  const _RouteError({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, color: colors.orange, size: 44),
            const SizedBox(height: TochSpacing.md),
            Text(
              'Activiteit niet gevonden',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TochSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TochSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Opnieuw proberen'),
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Terug'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
