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
      backgroundColor: colors.green,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.green),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fontSize = (constraints.maxWidth * .23).clamp(
                  72.0,
                  118.0,
                );
                return Center(
                  child: TochWordmark(fontSize: fontSize, onDark: true),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
