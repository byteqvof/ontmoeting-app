import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/usecases/is_profile_onboarding_required.dart';

class ProfileCompletionGate extends StatefulWidget {
  const ProfileCompletionGate({required this.child, super.key});

  final Widget child;

  static void resetSessionCache() {
    _ProfileCompletionGateState.resetSessionCache();
  }

  @override
  State<ProfileCompletionGate> createState() => _ProfileCompletionGateState();
}

class _ProfileCompletionGateState extends State<ProfileCompletionGate> {
  late Future<_ProfileGateResult> _profileRequired = _isProfileRequired();

  static String? _completeUserKey;
  static _ProfileGateResult? _completeResult;
  static Future<_ProfileGateResult>? _profileGateFuture;

  static void resetSessionCache() {
    _completeUserKey = null;
    _completeResult = null;
    _profileGateFuture = null;
  }

  Future<_ProfileGateResult> _isProfileRequired({
    bool forceRefresh = false,
  }) async {
    final userKey = _currentProfileGateUserKey(context);
    final cachedResult = _completeResult;
    if (!forceRefresh &&
        _completeUserKey == userKey &&
        cachedResult?.status == _ProfileGateStatus.complete) {
      return cachedResult!;
    }

    final currentFuture = _profileGateFuture;
    if (!forceRefresh && _completeUserKey == userKey && currentFuture != null) {
      return currentFuture;
    }

    _completeUserKey = userKey;
    late final Future<_ProfileGateResult> future;
    future = _fetchProfileRequired()
        .then((result) {
          if (result.status == _ProfileGateStatus.complete) {
            _completeUserKey = userKey;
            _completeResult = result;
          }
          return result;
        })
        .whenComplete(() {
          if (identical(_profileGateFuture, future)) {
            _profileGateFuture = null;
          }
        });
    _profileGateFuture = future;
    return future;
  }

  Future<_ProfileGateResult> _fetchProfileRequired() async {
    final result = await sl<IsProfileOnboardingRequired>()(const NoParams());
    return result.fold(
      (failure) => failure is NetworkFailure
          ? const _ProfileGateResult.complete()
          : _ProfileGateResult.error(failure.message),
      (required) => required
          ? const _ProfileGateResult.required()
          : const _ProfileGateResult.complete(),
    );
  }

  void _retry() {
    setState(() {
      _profileRequired = _isProfileRequired(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileGateResult>(
      future: _profileRequired,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ProfileGateLoading();
        }

        final result = snapshot.data;
        if (result?.status == _ProfileGateStatus.error) {
          return _ProfileGateError(message: result?.message, onRetry: _retry);
        }

        if (result?.status == _ProfileGateStatus.required) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.profileSetup);
            }
          });
          return const _ProfileGateLoading();
        }

        return widget.child;
      },
    );
  }
}

String _currentProfileGateUserKey(BuildContext context) {
  try {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.id.isNotEmpty) {
      return state.user.id;
    }
  } catch (_) {
    // Tests and early app startup can build the gate without an AuthBloc.
  }
  return '__unknown_user__';
}

enum _ProfileGateStatus { complete, required, error }

class _ProfileGateResult {
  const _ProfileGateResult._(this.status, [this.message]);

  const _ProfileGateResult.complete() : this._(_ProfileGateStatus.complete);

  const _ProfileGateResult.required() : this._(_ProfileGateStatus.required);

  const _ProfileGateResult.error(String message)
    : this._(_ProfileGateStatus.error, message);

  final _ProfileGateStatus status;
  final String? message;
}

class _ProfileGateLoading extends StatelessWidget {
  const _ProfileGateLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(26),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.green),
                const SizedBox(height: 14),
                Text(
                  'Profiel controleren',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGateError extends StatelessWidget {
  const _ProfileGateError({required this.onRetry, this.message});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: TochShadows.raised(colors),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.green100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: SizedBox.square(
                          dimension: 64,
                          child: Icon(
                            Icons.account_circle_outlined,
                            color: colors.green,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: TochSpacing.md),
                      Text(
                        'Profielstatus onbekend',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: TochSpacing.xs),
                      Text(
                        message ??
                            'We kunnen nu niet controleren of je profiel compleet is.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.ink3,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: TochSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Opnieuw proberen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
