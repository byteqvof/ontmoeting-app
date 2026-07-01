import 'package:flutter/material.dart';

IconData tochCategoryIcon({String? id, String? label, String? iconKey}) {
  final tokens = {_normalize(id), _normalize(label), _normalize(iconKey)}
    ..remove('');

  bool hasAny(Set<String> aliases) => tokens.any(aliases.contains);

  if (hasAny(_fishingAliases)) return Icons.phishing_rounded;
  if (hasAny(_walkingAliases)) return Icons.directions_walk_rounded;
  if (hasAny(_coffeeAliases)) return Icons.local_cafe_rounded;
  if (hasAny(_foodAliases)) return Icons.restaurant_rounded;
  if (hasAny(_cultureAliases)) return Icons.palette_rounded;
  if (hasAny(_musicAliases)) return Icons.music_note_rounded;
  if (hasAny(_sportAliases)) return Icons.sports_basketball_rounded;
  if (hasAny(_gamingAliases)) return Icons.sports_esports_rounded;
  if (hasAny(_motorAliases)) return Icons.two_wheeler_rounded;
  if (hasAny(_boardGameAliases)) return Icons.casino_rounded;
  if (hasAny(_photoAliases)) return Icons.photo_camera_rounded;
  if (hasAny(_socialAliases)) return Icons.groups_rounded;
  if (hasAny(_networkingAliases)) return Icons.groups_2_rounded;
  if (hasAny(_volunteeringAliases)) return Icons.volunteer_activism_rounded;
  if (hasAny(_outdoorAliases)) return Icons.park_rounded;
  if (hasAny(_allAliases)) return Icons.explore_rounded;

  return Icons.local_activity_rounded;
}

String _normalize(String? value) {
  final normalized = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('&', ' en ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized;
}

const _allAliases = {'all', 'alles'};

const _fishingAliases = {
  'fish',
  'fishing',
  'phishing',
  'set_meal',
  'vis',
  'vissen',
};

const _walkingAliases = {
  'directions_walk',
  'hiking',
  'walk',
  'walking',
  'wandelen',
};

const _coffeeAliases = {'cafe', 'coffee', 'koffie', 'local_cafe'};

const _foodAliases = {
  'dining',
  'drinks',
  'eten',
  'eten_en_drinken',
  'food',
  'food_drinks',
  'restaurant',
  'utensils',
};

const _cultureAliases = {'culture', 'cultuur', 'museum', 'palette', 'theater'};

const _musicAliases = {'music', 'music_note', 'muziek'};

const _sportAliases = {'dumbbell', 'sport', 'sports', 'sports_basketball'};

const _gamingAliases = {'game', 'gaming', 'sports_esports'};

const _motorAliases = {'motor', 'motorcycle', 'two_wheeler'};

const _boardGameAliases = {
  'boardgames',
  'bordspellen',
  'casino',
  'dice_5',
  'games',
  'spelletjes',
};

const _photoAliases = {'camera', 'foto', 'photo', 'photo_camera'};

const _socialAliases = {'favorite', 'groups', 'sociaal', 'social', 'users'};

const _networkingAliases = {'network', 'networking', 'netwerken'};

const _volunteeringAliases = {
  'heart_handshake',
  'volunteering',
  'vrijwilligerswerk',
};

const _outdoorAliases = {
  'buiten',
  'nature',
  'natuur',
  'outdoor',
  'outdoors',
  'park',
  'trees',
};
