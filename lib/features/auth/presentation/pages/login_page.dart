import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../domain/entities/auth_oauth_provider.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/email_auth_divider.dart';
import '../widgets/social_auth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          showTochSnackBar(
            context,
            state.message,
            type: TochSnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthScreenShell(
          title: 'Welkom\nterug',
          subtitle: 'Log in en sluit aan bij wat er vandaag speelt.',
          children: [
            SocialAuthButton(
              icon: Icons.apple,
              label: 'Inloggen met Apple',
              dark: true,
              onPressed: isLoading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthOAuthSignInRequested(AuthOAuthProvider.apple),
                    ),
            ),
            const SizedBox(height: TochSpacing.sm),
            SocialAuthButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Doorgaan met Google',
              onPressed: isLoading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthOAuthSignInRequested(AuthOAuthProvider.google),
                    ),
            ),
            const EmailAuthDivider(),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'E-mailadres',
                    keyboardType: TextInputType.emailAddress,
                    validator: InputValidators.email,
                  ),
                  const SizedBox(height: TochSpacing.md),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Wachtwoord',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: InputValidators.password,
                  ),
                  const SizedBox(height: TochSpacing.lg),
                  AuthSubmitButton(
                    label: 'Inloggen',
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.go(AppRoutes.register),
              child: const Text('Nog geen account? Maak er een aan'),
            ),
          ],
        );
      },
    );
  }
}
