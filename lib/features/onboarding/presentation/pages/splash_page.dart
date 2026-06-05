import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_mark.dart';
import '../../../../app/widgets/toch_wordmark.dart';

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
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.green, const Color(0xFF163D2C)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        TochMark(size: 92),
                        SizedBox(height: TochSpacing.lg),
                        TochWordmark(fontSize: 56, onDark: true),
                      ],
                    ),
                  ),
                  Positioned(
                    left: TochSpacing.xl,
                    right: TochSpacing.xl,
                    bottom: TochSpacing.xxl,
                    child: Column(
                      children: [
                        Text(
                          'Ik ga toch.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.cream),
                        ),
                        const SizedBox(height: TochSpacing.xs),
                        Text(
                          'Sluit aan als je wilt.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.cream.withValues(alpha: .64),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
