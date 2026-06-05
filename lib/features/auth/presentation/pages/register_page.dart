import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
import '../../../../core/utils/input_validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
      AuthSignUpRequested(
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
                            const TochWordmark(),
                            const SizedBox(height: TochSpacing.lg),
                            Text(
                              'Begin rustig',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: TochSpacing.sm),
                            Text(
                              'Maak een account aan en ontdek laagdrempelige ontmoetingen om je heen.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: TochSpacing.xl),
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email',
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
                              child: const Text('Ik heb al een account'),
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
