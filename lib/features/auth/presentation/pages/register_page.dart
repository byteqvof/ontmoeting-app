import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_mark.dart';
import '../../../../core/utils/input_validators.dart';
import '../../domain/entities/auth_oauth_provider.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/email_auth_divider.dart';
import '../widgets/social_auth_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.length < 2) {
      return 'Naam is verplicht';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailVerificationPending) {
          context.go(AppRoutes.emailVerificationPath(state.email));
          return;
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TochMark(size: 56),
                            const SizedBox(height: TochSpacing.lg),
                            Text(
                              'Maak je\naccount aan',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(fontSize: 42, height: 1.04),
                            ),
                            const SizedBox(height: TochSpacing.sm),
                            Text(
                              'Een minuut werk. Daarna zie je meteen wat er bij jou in de buurt gebeurt.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: TochSpacing.lg),
                            SocialAuthButton(
                              icon: Icons.apple,
                              label: 'Doorgaan met Apple',
                              onPressed: isLoading
                                  ? null
                                  : () => context.read<AuthBloc>().add(
                                      const AuthOAuthSignInRequested(
                                        AuthOAuthProvider.apple,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: TochSpacing.sm),
                            SocialAuthButton(
                              icon: Icons.g_mobiledata,
                              label: 'Doorgaan met Google',
                              onPressed: isLoading
                                  ? null
                                  : () => context.read<AuthBloc>().add(
                                      const AuthOAuthSignInRequested(
                                        AuthOAuthProvider.google,
                                      ),
                                    ),
                            ),
                            const EmailAuthDivider(),
                            AuthTextField(
                              controller: _nameController,
                              label: 'Je naam',
                              keyboardType: TextInputType.name,
                              validator: _validateName,
                            ),
                            const SizedBox(height: TochSpacing.md),
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
                              label: 'Account aanmaken',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: TochSpacing.sm),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.login),
                              child: const Text(
                                'Heb je al een account? Inloggen',
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
          ),
        );
      },
    );
  }
}
