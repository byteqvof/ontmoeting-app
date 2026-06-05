import 'package:flutter/material.dart';

import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_location.dart';

abstract interface class HomeDummyDataSource {
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  });
}

class HomeDummyDataSourceImpl implements HomeDummyDataSource {
  const HomeDummyDataSourceImpl();

  @override
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  }) async {
    const categories = [
      HomeCategory(
        id: 'all',
        label: 'Alles',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF19211C),
        backgroundColor: Color(0xFFFFFFFF),
      ),
      HomeCategory(
        id: 'fishing',
        label: 'Vissen',
        icon: Icons.set_meal_rounded,
        color: Color(0xFF2F8C86),
        backgroundColor: Color(0xFFE1F0EE),
      ),
      HomeCategory(
        id: 'walking',
        label: 'Wandelen',
        icon: Icons.directions_walk_rounded,
        color: Color(0xFF5B8A33),
        backgroundColor: Color(0xFFECF2E1),
      ),
      HomeCategory(
        id: 'coffee',
        label: 'Koffie',
        icon: Icons.local_cafe_rounded,
        color: Color(0xFF9A6A43),
        backgroundColor: Color(0xFFF1E8DF),
      ),
      HomeCategory(
        id: 'sport',
        label: 'Sport',
        icon: Icons.sports_basketball_rounded,
        color: Color(0xFFD9703C),
        backgroundColor: Color(0xFFFAE9DD),
      ),
      HomeCategory(
        id: 'gaming',
        label: 'Gaming',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF5A5AC0),
        backgroundColor: Color(0xFFE8E8F7),
      ),
      HomeCategory(
        id: 'motor',
        label: 'Motor',
        icon: Icons.two_wheeler_rounded,
        color: Color(0xFF5E6770),
        backgroundColor: Color(0xFFE8ECEF),
      ),
      HomeCategory(
        id: 'boardgames',
        label: 'Bordspellen',
        icon: Icons.casino_rounded,
        color: Color(0xFF9A4E8A),
        backgroundColor: Color(0xFFF4E6F1),
      ),
      HomeCategory(
        id: 'photo',
        label: 'Fotografie',
        icon: Icons.photo_camera_rounded,
        color: Color(0xFF3E72B0),
        backgroundColor: Color(0xFFE4ECF6),
      ),
      HomeCategory(
        id: 'social',
        label: 'Sociaal',
        icon: Icons.favorite_rounded,
        color: Color(0xFFC25A6B),
        backgroundColor: Color(0xFFF7E3E7),
      ),
    ];

    final activities = [
      HomeActivity(
        id: 'maas-fishing',
        category: categories[1],
        distanceKm: 3.2,
        distanceLabel: '3,2 km',
        title: 'Avondvissen aan de Maas',
        dateLabel: 'vrijdag 6 jun',
        timeLabel: '19:00',
        hostName: 'Rick',
        participantInitials: const ['RH', 'JB', 'SV'],
        spotsLabel: 'nog 3 plekken',
      ),
      HomeActivity(
        id: 'coffeelovers',
        category: categories[3],
        distanceKm: 1.1,
        distanceLabel: '1,1 km',
        title: 'Ochtendkoffie bij Coffeelovers',
        dateLabel: 'zaterdag 7 jun',
        timeLabel: '09:30',
        hostName: 'Sanne',
        participantInitials: const ['SV', 'ES', 'NE', '+1'],
        spotsLabel: 'nog 3 plekken',
      ),
      HomeActivity(
        id: 'sint-pietersberg',
        category: categories[2],
        distanceKm: 4.5,
        distanceLabel: '4,5 km',
        title: 'Zondagochtend Sint-Pietersberg',
        dateLabel: 'zondag 8 jun',
        timeLabel: '08:00',
        hostName: 'Daan',
        participantInitials: const ['DC', 'LP', 'MR'],
        spotsLabel: 'nog 6 plekken',
      ),
      HomeActivity(
        id: 'fifa-evening',
        category: categories[5],
        distanceKm: 2.0,
        distanceLabel: '2,0 km',
        title: 'FIFA-avond, gewoon gezellig',
        dateLabel: 'vrijdag 6 jun',
        timeLabel: '20:30',
        hostName: 'Milan',
        participantInitials: const ['MR', 'YD'],
        spotsLabel: 'nog 3 plekken',
      ),
      HomeActivity(
        id: 'heuvelland',
        category: categories[6],
        distanceKm: 5.8,
        distanceLabel: '5,8 km',
        title: 'Toertocht door het Heuvelland',
        dateLabel: 'zondag 8 jun',
        timeLabel: '10:00',
        hostName: 'Joost',
        participantInitials: const ['JB', 'BJ', 'RH', '+3'],
        spotsLabel: 'jij gaat ook',
        isJoined: true,
      ),
      HomeActivity(
        id: 'catan',
        category: categories[7],
        distanceKm: 0.8,
        distanceLabel: '0,8 km',
        title: 'Catan & co. bij Boekie',
        dateLabel: 'donderdag 5 jun',
        timeLabel: '19:30',
        hostName: 'Lotte',
        participantInitials: const ['LP', 'FD', 'NE'],
        spotsLabel: 'nog 3 plekken',
      ),
      HomeActivity(
        id: 'stadspark-run',
        category: categories[4],
        distanceKm: 1.4,
        distanceLabel: '1,4 km',
        title: 'Hardlopen - 5K rondje Stadspark',
        dateLabel: 'maandag 9 jun',
        timeLabel: '18:30',
        hostName: 'Fenna',
        participantInitials: const ['FD'],
        spotsLabel: 'nog 6 plekken',
      ),
      HomeActivity(
        id: 'golden-hour',
        category: categories[8],
        distanceKm: 2.7,
        distanceLabel: '2,7 km',
        title: 'Golden hour fotowandeling',
        dateLabel: 'zaterdag 7 jun',
        timeLabel: '21:00',
        hostName: 'Noor',
        participantInitials: const ['NE', 'DC'],
        spotsLabel: 'nog 5 plekken',
      ),
    ];

    return HomeFeed(
      locationName: location.cityName,
      selectedTimeFilter: 'Alles',
      selectedDistanceKm: distanceKm,
      timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
      distanceFilters: const [5, 10, 25, 50],
      categories: categories,
      activities: activities
          .where((activity) => activity.distanceKm <= distanceKm)
          .toList(),
    );
  }
}
