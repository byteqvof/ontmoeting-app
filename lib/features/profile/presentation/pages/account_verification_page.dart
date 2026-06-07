import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/account_trust_service.dart';
import '../../domain/entities/profile_trust.dart';

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});

  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
  late Future<ProfileTrust> _trustFuture = _loadTrust();

  Future<ProfileTrust> _loadTrust() {
    return sl<AccountTrustService>().syncTrust();
  }

  void _refresh() {
    setState(() {
      _trustFuture = _loadTrust();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      appBar: AppBar(
        title: const Text('Account & verificatie'),
        backgroundColor: colors.cream,
        foregroundColor: colors.ink,
        elevation: 0,
      ),
      body: FutureBuilder<ProfileTrust>(
        future: _trustFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: colors.green),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(TochSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status laden lukt niet.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: TochSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Opnieuw proberen'),
                    ),
                  ],
                ),
              ),
            );
          }

          final trust = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(TochSpacing.lg),
            children: [
              _StatusTile(
                icon: Icons.phone_android_rounded,
                title: 'Telefoon',
                value: trust.phoneStatusLabel,
                isConfirmed: trust.phoneVerified,
              ),
              const SizedBox(height: TochSpacing.md),
              _StatusTile(
                icon: Icons.badge_outlined,
                title: 'Identiteit',
                value: trust.identityStatusLabel,
                isConfirmed: trust.identityVerified,
                helper:
                    'Deze status betekent alleen dat identiteit bevestigd kan zijn. Het zegt niets over iemands gedrag.',
              ),
              const SizedBox(height: TochSpacing.md),
              _StatusTile(
                icon: Icons.trending_up_rounded,
                title: 'Reputatie',
                value:
                    '${trust.reputationLabel} · ${trust.reputationScore}/100',
                isConfirmed: trust.reputationScore > 0,
                helper:
                    'Gebaseerd op afgeronde activiteiten, opkomst, reviews en moderatiegegevens.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isConfirmed,
    this.helper,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isConfirmed;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isConfirmed ? colors.green100 : colors.orangeSoft,
                borderRadius: BorderRadius.circular(TochRadius.md),
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  icon,
                  color: isConfirmed ? colors.green : colors.orange,
                  size: 25,
                ),
              ),
            ),
            const SizedBox(width: TochSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.green700.withValues(alpha: .72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (helper != null) ...[
                    const SizedBox(height: TochSpacing.xs),
                    Text(
                      helper!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.green700.withValues(alpha: .7),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isConfirmed ? Icons.check_circle_rounded : Icons.info_rounded,
              color: isConfirmed ? colors.green : colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
