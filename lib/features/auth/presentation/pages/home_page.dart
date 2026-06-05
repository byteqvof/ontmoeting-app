import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
import '../bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TochWordmark(fontSize: 34),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final email = state is AuthAuthenticated ? state.user.email : '';

          return Padding(
            padding: const EdgeInsets.all(TochSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Je bent binnen.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: TochSpacing.md),
                    Text(
                      'Een kleine stap is genoeg. Straks tonen we hier ontmoetingen die dichtbij en laagdrempelig voelen.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: TochSpacing.xl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.toch.card,
                        border: Border.all(color: context.toch.line),
                        borderRadius: BorderRadius.circular(TochRadius.lg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(TochSpacing.lg),
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: context.toch.green100,
                                borderRadius: BorderRadius.circular(
                                  TochRadius.md,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(TochSpacing.md),
                                child: Icon(
                                  Icons.favorite_border,
                                  color: context.toch.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: TochSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email.isEmpty ? 'Welkom' : email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: TochSpacing.xs),
                                  Text(
                                    'Rustig, warm en zonder druk.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
