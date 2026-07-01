import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_mark.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_submit_button.dart';

enum EmailVerificationPageMode { pending, success }

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({required this.mode, this.email, super.key});

  final EmailVerificationPageMode mode;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailVerificationPending &&
            state.errorMessage != null) {
          showTochSnackBar(
            context,
            state.errorMessage!,
            type: TochSnackBarType.error,
          );
        }
        if (state is AuthEmailVerificationPending &&
            state.noticeMessage != null) {
          showTochSnackBar(
            context,
            state.noticeMessage!,
            type: TochSnackBarType.success,
          );
        }
      },
      builder: (context, state) {
        final pendingState = state is AuthEmailVerificationPending
            ? state
            : null;
        final resolvedEmail = email ?? pendingState?.email ?? '';
        final colors = context.toch;
        return Scaffold(
          backgroundColor: colors.cream,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: TochShadows.raised(colors),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: mode == EmailVerificationPageMode.success
                          ? _EmailVerifiedContent()
                          : _EmailVerificationPendingContent(
                              email: resolvedEmail,
                              isResending: pendingState?.isResending ?? false,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmailVerificationPendingContent extends StatelessWidget {
  const _EmailVerificationPendingContent({
    required this.email,
    required this.isResending,
  });

  final String email;
  final bool isResending;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final canResend = email.trim().isNotEmpty && !isResending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TochMark(size: 64, backgroundColor: colors.green),
        const SizedBox(height: TochSpacing.lg),
        Text(
          'Check je\nmail',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 42, height: 1.04),
        ),
        const SizedBox(height: TochSpacing.sm),
        Text(
          email.isEmpty
              ? 'We hebben je een verificatielink gestuurd. Open de link op dit toestel om je account te activeren.'
              : 'We hebben een verificatielink gestuurd naar $email. Open de link op dit toestel om je account te activeren.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.ink3,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TochSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.md),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Text(
                    'De link opent TOCH automatisch en bevestigt je e-mailadres.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.green700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TochSpacing.lg),
        AuthSubmitButton(
          label: 'Verificatiemail opnieuw sturen',
          isLoading: isResending,
          onPressed: canResend
              ? () => context.read<AuthBloc>().add(
                  AuthVerificationEmailResendRequested(email),
                )
              : null,
        ),
        const SizedBox(height: TochSpacing.sm),
        TextButton(
          onPressed: isResending ? null : () => context.go(AppRoutes.login),
          child: const Text('Terug naar inloggen'),
        ),
      ],
    );
  }
}

class _EmailVerifiedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TochMark(size: 64, backgroundColor: colors.green),
        const SizedBox(height: TochSpacing.lg),
        Text(
          'E-mail\nbevestigd',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 42, height: 1.04),
        ),
        const SizedBox(height: TochSpacing.sm),
        Text(
          'Je e-mailadres is bevestigd. Je kunt nu verder met je account.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.ink3,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TochSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 90,
            child: Icon(Icons.verified_rounded, color: colors.green, size: 58),
          ),
        ),
        const SizedBox(height: TochSpacing.lg),
        AuthSubmitButton(
          label: 'Doorgaan',
          isLoading: false,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}
