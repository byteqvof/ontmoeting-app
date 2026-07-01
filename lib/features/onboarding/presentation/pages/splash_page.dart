import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2100), _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) {
      return;
    }
    final preferences = sl<AppPreferences>();
    context.go(
      preferences.hasSeenInitialFti ? AppRoutes.login : AppRoutes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.greenPressed,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.green),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wordmarkWidth = (constraints.maxWidth * .68).clamp(
                  220.0,
                  320.0,
                );
                return Stack(
                  children: [
                    Positioned(
                      top: constraints.maxHeight * .24,
                      left: (constraints.maxWidth - 320) / 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.green100.withValues(alpha: .18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const SizedBox.square(dimension: 320),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TochMark(
                            size: 78,
                            backgroundColor: colors.greenPressed,
                          ),
                          const SizedBox(height: TochSpacing.lg),
                          SizedBox(
                            width: wordmarkWidth,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TochWordmark(fontSize: 112, onDark: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 32,
                      right: 32,
                      bottom: 52,
                      child: Column(
                        children: [
                          Text(
                            'Ik ga toch.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ga je mee?',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .72),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: TochSpacing.md),
                          Text(
                            'TIK OM TE STARTEN',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .42),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
