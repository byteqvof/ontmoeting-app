import 'package:equatable/equatable.dart';

const homeDateFilterAll = 'all';
const homeDateFilterToday = 'today';
const homeDateFilterWeekend = 'weekend';
const homeDateFilterCustom = 'custom';

const homeSortDistance = 'distance';
const homeSortStartTime = 'start_time';
const homeSortParticipants = 'participants';

const tochAgeBands = ['18_24', '25_34', '35_44', '45_54', '55_64', '65_plus'];

const tochGenderValues = ['woman', 'man', 'non_binary', 'prefer_not_to_say'];

class HomeFeedFilters extends Equatable {
  const HomeFeedFilters({
    this.distanceKm = 10,
    this.dateFilter = homeDateFilterAll,
    this.dateFrom,
    this.dateTo,
    this.categoryIds = const [],
    this.targetAgeBands = const [],
    this.targetGenders = const [],
    this.requiresIdentityVerified = false,
    this.availableOnly = false,
    this.minParticipants,
    this.maxParticipants,
    this.sort = homeSortDistance,
  });

  final int distanceKm;
  final String dateFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String> categoryIds;
  final List<String> targetAgeBands;
  final List<String> targetGenders;
  final bool requiresIdentityVerified;
  final bool availableOnly;
  final int? minParticipants;
  final int? maxParticipants;
  final String sort;

  String get selectedCategoryId =>
      categoryIds.length == 1 ? categoryIds.first : 'all';

  String get selectedTimeFilter {
    return switch (dateFilter) {
      homeDateFilterToday => 'Vandaag',
      homeDateFilterWeekend => 'Dit weekend',
      homeDateFilterCustom => 'Datum',
      _ => 'Alles',
    };
  }

  bool get hasAdvancedFilters =>
      distanceKm != 10 ||
      dateFilter != homeDateFilterAll ||
      categoryIds.isNotEmpty ||
      targetAgeBands.isNotEmpty ||
      targetGenders.isNotEmpty ||
      requiresIdentityVerified ||
      availableOnly ||
      minParticipants != null ||
      maxParticipants != null ||
      sort != homeSortDistance;

  HomeFeedFilters copyWith({
    int? distanceKm,
    String? dateFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearDateRange = false,
    List<String>? categoryIds,
    List<String>? targetAgeBands,
    List<String>? targetGenders,
    bool? requiresIdentityVerified,
    bool? availableOnly,
    int? minParticipants,
    int? maxParticipants,
    bool clearParticipants = false,
    String? sort,
  }) {
    return HomeFeedFilters(
      distanceKm: distanceKm ?? this.distanceKm,
      dateFilter: dateFilter ?? this.dateFilter,
      dateFrom: clearDateRange ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateRange ? null : dateTo ?? this.dateTo,
      categoryIds: categoryIds ?? this.categoryIds,
      targetAgeBands: targetAgeBands ?? this.targetAgeBands,
      targetGenders: targetGenders ?? this.targetGenders,
      requiresIdentityVerified:
          requiresIdentityVerified ?? this.requiresIdentityVerified,
      availableOnly: availableOnly ?? this.availableOnly,
      minParticipants: clearParticipants
          ? null
          : minParticipants ?? this.minParticipants,
      maxParticipants: clearParticipants
          ? null
          : maxParticipants ?? this.maxParticipants,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
    distanceKm,
    dateFilter,
    dateFrom,
    dateTo,
    categoryIds,
    targetAgeBands,
    targetGenders,
    requiresIdentityVerified,
    availableOnly,
    minParticipants,
    maxParticipants,
    sort,
  ];
}

String ageBandLabel(String value) {
  return switch (value) {
    '18_24' => '18-24',
    '25_34' => '25-34',
    '35_44' => '35-44',
    '45_54' => '45-54',
    '55_64' => '55-64',
    '65_plus' => '65+',
    _ => value,
  };
}

String genderLabel(String value) {
  return switch (value) {
    'woman' => 'Vrouwen',
    'man' => 'Mannen',
    'non_binary' => 'Non-binair',
    'prefer_not_to_say' => 'Niet tonen',
    _ => value,
  };
}

String reputationLevelLabel(String value) {
  return switch (value) {
    'active_member' => 'Actief lid',
    'known_member' => 'Bekend lid',
    'top_participant' => 'Top deelnemer',
    _ => 'Nieuw lid',
  };
}
