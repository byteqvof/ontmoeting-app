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
    this.currentPositionTimeout = const Duration(seconds: 10),
    this.geocodingTimeout = const Duration(seconds: 2),
  });

  final Duration currentPositionTimeout;
  final Duration geocodingTimeout;

  @override
  Future<HomeLocation> getCurrentLocation({bool forceRefresh = false}) async {
    AppLogger.debug(
      'Location lookup started '
      'forceRefresh=$forceRefresh '
      'platform=${_platformLabel()} '
      'preferAndroidLocationManager=$_preferAndroidLocationManager '
      'timeout=${currentPositionTimeout.inSeconds}s',
    );
    await _ensureLocationAccess();

    final position = await _getQuickPosition(forceRefresh: forceRefresh);
    return _locationFromPosition(position);
  }

  @override
  Stream<HomeLocation> watchCurrentLocation() async* {
    AppLogger.debug(
      'Location watcher starting '
      'platform=${_platformLabel()} '
      'preferAndroidLocationManager=$_preferAndroidLocationManager',
    );
    await _ensureLocationAccess();
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _locationSettings(
        forceAndroidLocationManager: _preferAndroidLocationManager,
        distanceFilter: 25,
      ),
    )) {
      yield await _locationFromPosition(position);
    }
  }

  Future<Position> _getQuickPosition({required bool forceRefresh}) async {
    if (forceRefresh) {
      return _requestCurrentPosition(
        forceAndroidLocationManager: _preferAndroidLocationManager,
      );
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

    return _requestCurrentPosition(
      forceAndroidLocationManager: _preferAndroidLocationManager,
    );
  }

  Future<Position> _requestCurrentPosition({
    bool forceAndroidLocationManager = false,
  }) async {
    AppLogger.debug(
      'Requesting current location '
      '(androidLocationManager: $forceAndroidLocationManager)',
    );
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(
          forceAndroidLocationManager: forceAndroidLocationManager,
          timeLimit: currentPositionTimeout,
        ),
      );

      AppLogger.debug(
        'Current location received: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } on TimeoutException catch (error) {
      AppLogger.debug('Current location quick lookup timed out', error: error);
      if (forceAndroidLocationManager && _preferAndroidLocationManager) {
        AppLogger.debug(
          'Retrying current location with fused provider after '
          'Android LocationManager timeout',
        );
        return _requestCurrentPosition(forceAndroidLocationManager: false);
      }
      throw TimeoutException(
        'Location timed out before the device returned a fix.',
        currentPositionTimeout,
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Current location request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _ensureLocationAccess() async {
    AppLogger.debug('Checking location access on ${_platformLabel()}');
    var permission = await Geolocator.checkPermission();
    AppLogger.debug('Location permission before request: ${permission.name}');
    if (permission == LocationPermission.denied) {
      AppLogger.debug('Requesting location permission from platform');
      permission = await Geolocator.requestPermission();
      AppLogger.debug('Location permission after request: ${permission.name}');
    }

    if (permission == LocationPermission.denied) {
      AppLogger.debug('Location permission denied by user/platform');
      throw const PermissionDeniedException('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.debug('Location permission denied forever');
      throw const PermissionDeniedException(
        'Location permission permanently denied.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.debug('Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }
    AppLogger.debug('Location access granted and service enabled');
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
        'City lookup failed; using generic current location label',
        error: error,
      );
    }

    return 'Huidige locatie';
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
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        forceLocationManager: forceAndroidLocationManager,
        timeLimit: timeLimit,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  bool get _preferAndroidLocationManager =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }
}
