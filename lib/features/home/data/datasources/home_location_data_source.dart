import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/home_location.dart';

abstract interface class HomeLocationDataSource {
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false});

  Stream<HomeLocation> watchCurrentLocation();
}

class HomeLocationDataSourceImpl implements HomeLocationDataSource {
  const HomeLocationDataSourceImpl({
    this.useDeviceLocation = false,
    this.currentPositionTimeout = const Duration(seconds: 8),
    this.geocodingTimeout = const Duration(seconds: 3),
  });

  final bool useDeviceLocation;
  final Duration currentPositionTimeout;
  final Duration geocodingTimeout;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    if (!useDeviceLocation) {
      throw StateError('Device location is disabled.');
    }

    await _ensureLocationAccess();

    final position = await _getQuickPosition(forceRefresh: forceRefresh);
    if (position == null) {
      AppLogger.debug('No quick location fix available');
      throw TimeoutException('No location fix.');
    }

    return _locationFromPosition(position);
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    if (!useDeviceLocation) {
      throw StateError('Device location is disabled.');
    }

    await _ensureLocationAccess();
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _locationSettings(
        forceAndroidLocationManager: false,
        distanceFilter: 25,
      ),
    )) {
      yield await _locationFromPosition(position);
    }
  }

  Future<Position?> _getQuickPosition({required bool forceRefresh}) async {
    if (forceRefresh) {
      final currentPosition = await _requestCurrentPosition();
      return currentPosition ?? _lastKnownPosition();
    }

    final lastKnownPosition = await _lastKnownPosition();
    return lastKnownPosition ?? _requestCurrentPosition();
  }

  Future<Position?> _lastKnownPosition() async {
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

    return null;
  }

  Future<Position?> _requestCurrentPosition() async {
    AppLogger.debug('Requesting current location briefly');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(
          forceAndroidLocationManager: false,
          timeLimit: currentPositionTimeout,
        ),
      ).timeout(currentPositionTimeout + const Duration(milliseconds: 300));

      AppLogger.debug(
        'Current location received: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } on TimeoutException catch (error) {
      AppLogger.debug('Current location quick lookup timed out', error: error);
      return null;
    }
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

    final city = await _resolveCityName(position);
    return HomeLocation(
      cityName: city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String> _resolveCityName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(geocodingTimeout);

      final placemark = placemarks.isEmpty ? null : placemarks.first;
      final city = _firstNotBlank([
        placemark?.locality,
        placemark?.subAdministrativeArea,
        placemark?.administrativeArea,
      ]);

      if (city != null) {
        AppLogger.debug('Resolved city from coordinates: $city');
        return city;
      }
    } catch (error) {
      AppLogger.debug(
        'City lookup timed out; using generic label',
        error: error,
      );
    }

    return 'Je locatie';
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
