import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_mark.dart';
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state is AuthEmailVerificationPending &&
            state.noticeMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
        }
      },
      builder: (context, state) {
        final pendingState = state is AuthEmailVerificationPending
            ? state
            : null;
        final resolvedEmail = email ?? pendingState?.email ?? '';
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TochSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.toch.card,
                      border: Border.all(color: context.toch.line),
                      borderRadius: BorderRadius.circular(TochRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(TochSpacing.xl),
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
        const TochMark(size: 56),
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: TochSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(TochRadius.md),
            border: Border.all(color: colors.green200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.md),
            child: Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: colors.green),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Text(
                    'De link opent TOCH automatisch en bevestigt je e-mailadres via Supabase.',
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
        const TochMark(size: 56),
        const SizedBox(height: TochSpacing.lg),
        Text(
          'Email\nbevestigd',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 42, height: 1.04),
        ),
        const SizedBox(height: TochSpacing.sm),
        Text(
          'Je e-mailadres is bevestigd. Je kunt nu verder met je account.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: TochSpacing.lg),
        Icon(Icons.verified_rounded, color: colors.green, size: 64),
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
