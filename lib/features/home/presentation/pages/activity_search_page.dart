import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/pip_mascot.dart';
import '../../../../app/widgets/toch_design_system.dart';

class ActivitySearchPage extends StatelessWidget {
  const ActivitySearchPage({super.key});

  static const _recentSearches = ['Avondvissen', 'Koffie centrum', 'Hardlopen'];

  static const _categories = [
    _SearchCategory('Vissen', Icons.phishing_rounded, 'vissen'),
    _SearchCategory('Wandelen', Icons.directions_walk_rounded, 'wandelen'),
    _SearchCategory('Koffie', Icons.local_cafe_rounded, 'koffie'),
    _SearchCategory('Sport', Icons.sports_basketball_rounded, 'sport'),
    _SearchCategory('Gaming', Icons.sports_esports_rounded, 'gaming'),
    _SearchCategory('Motor', Icons.two_wheeler_rounded, 'motor'),
    _SearchCategory('Bordspellen', Icons.casino_rounded, 'bordspel'),
    _SearchCategory('Foto', Icons.photo_camera_rounded, 'foto'),
    _SearchCategory('Sociaal', Icons.groups_rounded, 'sociaal'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: context.pop,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: colors.ink,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(
                              TochRadius.pill,
                            ),
                            boxShadow: TochShadows.card(colors),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: colors.ink3,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Zoek een activiteit...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colors.ink4,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                    children: [
                      const _SearchEmptyHero(),
                      const TochSectionLabel('Recent'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final search in _recentSearches)
                            TochPill(
                              label: search,
                              icon: Icons.history_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const TochSectionLabel('Categorieen'),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: .95,
                        children: [
                          for (final category in _categories)
                            _CategorySearchTile(category: category),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyHero extends StatelessWidget {
  const _SearchEmptyHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const SizedBox.square(
              dimension: 96,
              child: Center(
                child: PipMascot(expression: PipExpression.thinking, size: 72),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waar heb je zin in?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zoek op activiteit, plek of mens - of kies een categorie hieronder.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.ink3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySearchTile extends StatelessWidget {
  const _CategorySearchTile({required this.category});

  final _SearchCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final skin = tochCategorySkin(category.skinKey);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: skin.tint,
        borderRadius: BorderRadius.circular(TochRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: skin.color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: SizedBox.square(
                dimension: 42,
                child: Icon(category.icon, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchCategory {
  const _SearchCategory(this.label, this.icon, this.skinKey);

  final String label;
  final IconData icon;
  final String skinKey;
}
