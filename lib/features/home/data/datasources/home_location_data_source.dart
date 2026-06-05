import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/home_location.dart';

abstract interface class HomeLocationDataSource {
  Future<HomeLocation> getCurrentLocation();

  Stream<HomeLocation> watchCurrentLocation();
}

class HomeLocationDataSourceImpl implements HomeLocationDataSource {
  const HomeLocationDataSourceImpl();

  @override
  Future<HomeLocation> getCurrentLocation() async {
    await _ensureLocationAccess();

    final position = await _getBestAvailablePosition();
    return _locationFromPosition(position);
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    await _ensureLocationAccess();

    try {
      yield await _locationFromPosition(await _getBestAvailablePosition());
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Initial location lookup failed; keeping watcher alive',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await for (final position in Geolocator.getPositionStream(
      locationSettings: _locationSettings(forceAndroidLocationManager: true),
    )) {
      AppLogger.debug(
        'Location stream position received: '
        '${position.latitude}, ${position.longitude}',
      );
      yield await _locationFromPosition(position);
    }
  }

  Future<Position> _getBestAvailablePosition() async {
    AppLogger.debug('Checking last known location');
    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      AppLogger.debug(
        'Using last known location: '
        '${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}',
      );
      return lastKnownPosition;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      AppLogger.debug('Checking Android LocationManager last known location');
      final locationManagerLastKnown = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );
      if (locationManagerLastKnown != null) {
        AppLogger.debug(
          'Using Android LocationManager last known location: '
          '${locationManagerLastKnown.latitude}, '
          '${locationManagerLastKnown.longitude}',
        );
        return locationManagerLastKnown;
      }
    }

    try {
      return await _requestCurrentPosition(forceAndroidLocationManager: false);
    } on TimeoutException catch (error) {
      AppLogger.debug('Current location timed out', error: error);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        return await _requestCurrentPosition(forceAndroidLocationManager: true);
      } on TimeoutException catch (error) {
        AppLogger.debug(
          'Android LocationManager current location timed out',
          error: error,
        );
      }
    }

    return _firstStreamPosition();
  }

  Future<Position> _requestCurrentPosition({
    required bool forceAndroidLocationManager,
  }) async {
    AppLogger.debug(
      forceAndroidLocationManager
          ? 'Requesting current location via Android LocationManager'
          : 'Requesting current location',
    );
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings(
        forceAndroidLocationManager: forceAndroidLocationManager,
        timeLimit: const Duration(seconds: 12),
      ),
    ).timeout(const Duration(seconds: 14));

    AppLogger.debug(
      'Current location received: ${position.latitude}, ${position.longitude}',
    );
    return position;
  }

  Future<Position> _firstStreamPosition() async {
    AppLogger.debug('Waiting for first location stream position');
    final position = await Geolocator.getPositionStream(
      locationSettings: _locationSettings(
        forceAndroidLocationManager: true,
        distanceFilter: 0,
      ),
    ).first.timeout(const Duration(seconds: 14));

    AppLogger.debug(
      'First location stream position received: '
      '${position.latitude}, ${position.longitude}',
    );
    return position;
  }

  Future<void> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.debug('Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    AppLogger.debug('Location permission before request: ${permission.name}');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      AppLogger.debug('Location permission after request: ${permission.name}');
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionDeniedException('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission permanently denied.',
      );
    }
  }

  Future<HomeLocation> _locationFromPosition(Position position) async {
    AppLogger.debug(
      'Resolving city for coordinates: '
      '${position.latitude}, ${position.longitude}',
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    ).timeout(const Duration(seconds: 12));

    if (placemarks.isEmpty) {
      throw StateError('Could not resolve city from current location.');
    }

    final placemark = placemarks.first;
    final city = _firstNotBlank([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]);

    if (city == null) {
      throw StateError('Current location did not include a city name.');
    }

    AppLogger.debug('Resolved city from coordinates: $city');
    return HomeLocation(
      cityName: city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  String? _firstNotBlank(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  LocationSettings _locationSettings({
    required bool forceAndroidLocationManager,
    int distanceFilter = 25,
    Duration? timeLimit,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: distanceFilter,
        forceLocationManager: forceAndroidLocationManager,
        timeLimit: timeLimit,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }
}
