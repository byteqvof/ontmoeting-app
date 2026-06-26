import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_mark.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.greenPressed,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.cream),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TochMark(size: 74, backgroundColor: colors.green),
                          const SizedBox(height: 22),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(fontSize: 40, height: 1.04),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.ink3, height: 1.35),
                        ),
                        const SizedBox(height: 20),
                        const AuthSocialProofCard(),
                        const SizedBox(height: 22),
                        ...children,
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

class AuthSocialProofCard extends StatelessWidget {
  const AuthSocialProofCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.line),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 106,
                  height: 42,
                  child: Stack(
                    children: [
                      Positioned(left: 0, child: _AuthProofAvatar(label: 'SV')),
                      Positioned(
                        left: 27,
                        child: _AuthProofAvatar(label: 'RH'),
                      ),
                      Positioned(
                        left: 54,
                        child: _AuthProofAvatar(label: 'JB'),
                      ),
                      Positioned(
                        left: 81,
                        child: _AuthProofAvatar(label: 'EM'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '3.400+ anderen zijn al lid',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: _AuthProofStat(value: '1.240', label: 'activiteiten'),
                ),
                Expanded(
                  child: _AuthProofStat(value: '180', label: 'nu actief'),
                ),
                Expanded(
                  child: _AuthProofStat(value: '+85', label: 'connecties'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthProofAvatar extends StatelessWidget {
  const _AuthProofAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final color = switch (label) {
      'SV' => const Color(0xFF347E70),
      'RH' => const Color(0xFF93623B),
      'JB' => const Color(0xFF5E8B3A),
      _ => const Color(0xFFD2703C),
    };

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: colors.card, width: 3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AuthProofStat extends StatelessWidget {
  const _AuthProofStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.ink3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
