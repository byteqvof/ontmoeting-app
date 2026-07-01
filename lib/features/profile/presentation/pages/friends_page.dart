import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/friendship_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Future<List<FriendshipListItem>> _friendsFuture = _loadFriends();

  Future<List<FriendshipListItem>> _loadFriends() {
    return sl<FriendshipService>().listFriends();
  }

  void _refresh() {
    setState(() {
      _friendsFuture = _loadFriends();
    });
  }

  Future<void> _accept(FriendshipListItem item) async {
    await sl<FriendshipService>().accept(item.profileId);
    _refresh();
  }

  Future<void> _decline(FriendshipListItem item) async {
    await sl<FriendshipService>().decline(item.profileId);
    _refresh();
  }

  Future<void> _remove(FriendshipListItem item) async {
    await sl<FriendshipService>().remove(item.profileId);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      appBar: AppBar(
        title: const Text('Vrienden'),
        backgroundColor: colors.cream,
        foregroundColor: colors.ink,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FutureBuilder<List<FriendshipListItem>>(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(color: colors.green),
                );
              }

              if (snapshot.hasError) {
                return _FriendsStateCard(
                  icon: Icons.group_off_outlined,
                  title: 'Vrienden zijn nog niet bereikbaar',
                  body:
                      'Deze functie kan nu geen verbinding maken met de vriendenservice. Probeer opnieuw na de laatste backend-update.',
                  actionLabel: 'Opnieuw proberen',
                  onAction: _refresh,
                );
              }

              final friends = snapshot.data ?? const [];
              if (friends.isEmpty) {
                return _FriendsStateCard(
                  icon: Icons.group_outlined,
                  title: 'Nog geen vrienden',
                  body:
                      'Klik op een profiel na een leuke ontmoeting om iemand toe te voegen.',
                  actionLabel: 'Naar ontdekken',
                  onAction: () => context.go(AppRoutes.home),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  itemCount: friends.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TochSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = friends[index];
                    return _FriendTile(
                      item: item,
                      onAccept: () => _accept(item),
                      onDecline: () => _decline(item),
                      onRemove: () => _remove(item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.item,
    required this.onAccept,
    required this.onDecline,
    required this.onRemove,
  });

  final FriendshipListItem item;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isPending =
        item.status == FriendshipStatus.pendingReceived ||
        item.status == FriendshipStatus.pendingSent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.green100,
                  foregroundColor: colors.green,
                  backgroundImage: item.profile.avatarUrl == null
                      ? null
                      : NetworkImage(item.profile.avatarUrl!),
                  child: item.profile.avatarUrl == null
                      ? Text(
                          item.profile.initials,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                const SizedBox(width: TochSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusLabel(item),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.green700.withValues(alpha: .7),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open profiel',
                  onPressed: () =>
                      context.push(AppRoutes.profilePath(item.profileId)),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (isPending || item.status == FriendshipStatus.accepted) ...[
              const SizedBox(height: TochSpacing.sm),
              Row(
                children: [
                  if (item.status == FriendshipStatus.pendingReceived) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        child: const Text('Accepteer'),
                      ),
                    ),
                    const SizedBox(width: TochSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: const Text('Weiger'),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.person_remove_rounded),
                        label: Text(
                          item.status == FriendshipStatus.pendingSent
                              ? 'Trek verzoek in'
                              : 'Verwijder vriend',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendsStateCard extends StatelessWidget {
  const _FriendsStateCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.all(TochSpacing.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TochSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.green, size: 42),
              const SizedBox(height: TochSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TochSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.green700.withValues(alpha: .74),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: TochSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(FriendshipListItem item) {
  return switch (item.status) {
    FriendshipStatus.accepted => 'Vriend',
    FriendshipStatus.pendingSent => 'Verzoek verstuurd',
    FriendshipStatus.pendingReceived => 'Wil vrienden worden',
    _ => item.profile.cityName ?? 'TOCH',
  };
}
