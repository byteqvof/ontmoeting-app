import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/is_profile_onboarding_required.dart';

class ProfileCompletionGate extends StatefulWidget {
  const ProfileCompletionGate({required this.child, super.key});

  final Widget child;

  @override
  State<ProfileCompletionGate> createState() => _ProfileCompletionGateState();
}

class _ProfileCompletionGateState extends State<ProfileCompletionGate> {
  late Future<_ProfileGateResult> _profileRequired = _isProfileRequired();

  Future<_ProfileGateResult> _isProfileRequired() async {
    final result = await sl<IsProfileOnboardingRequired>()(const NoParams());
    return result.fold(
      (failure) => _ProfileGateResult.error(failure.message),
      (required) => required
          ? const _ProfileGateResult.required()
          : const _ProfileGateResult.complete(),
    );
  }

  void _retry() {
    setState(() {
      _profileRequired = _isProfileRequired();
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
    return Scaffold(
      backgroundColor: context.toch.cream,
      body: Center(child: CircularProgressIndicator(color: context.toch.green)),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(TochSpacing.xl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(TochRadius.lg),
                  border: Border.all(color: colors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(TochSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: colors.green,
                        size: 44,
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
