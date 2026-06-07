import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_location.dart';

const openFreeMapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

class ActivityMapCanvas extends StatefulWidget {
  const ActivityMapCanvas({
    required this.location,
    required this.activities,
    this.interactive = true,
    this.onCameraIdleLocation,
    super.key,
  });

  final HomeLocation location;
  final List<HomeActivity> activities;
  final bool interactive;
  final ValueChanged<HomeLocation>? onCameraIdleLocation;

  @override
  State<ActivityMapCanvas> createState() => _ActivityMapCanvasState();
}

class _ActivityMapCanvasState extends State<ActivityMapCanvas> {
  MapLibreMapController? _controller;
  bool _isStyleLoaded = false;

  @override
  void didUpdateWidget(covariant ActivityMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities ||
        oldWidget.location != widget.location) {
      if (oldWidget.location != widget.location) {
        unawaited(_moveCameraToLocation());
      }
      unawaited(_syncMarkers());
    }
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _controller = controller;
  }

  Future<void> _onStyleLoaded() async {
    _isStyleLoaded = true;
    await _syncMarkers();
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null || !_isStyleLoaded) {
      return;
    }

    if (controller.circles.isNotEmpty) {
      await controller.removeCircles(controller.circles);
    }

    await controller.addCircle(
      CircleOptions(
        geometry: LatLng(widget.location.latitude, widget.location.longitude),
        circleRadius: 7,
        circleColor: '#F2994A',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );

    final eventCircles = widget.activities
        .where((activity) => activity.latitude != 0 || activity.longitude != 0)
        .map(
          (activity) => CircleOptions(
            geometry: LatLng(activity.latitude, activity.longitude),
            circleRadius: widget.interactive ? 8 : 6,
            circleColor: '#1E5740',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        )
        .toList();

    if (eventCircles.isNotEmpty) {
      await controller.addCircles(eventCircles);
    }
  }

  Future<void> _moveCameraToLocation() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.location.latitude, widget.location.longitude),
        widget.interactive ? 11.5 : 10.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE7EBE0),
      child: Stack(
        children: [
          MapLibreMap(
            styleString: openFreeMapStyleUrl,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.location.latitude,
                widget.location.longitude,
              ),
              zoom: widget.interactive ? 11.5 : 10.8,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: () {
              unawaited(_onStyleLoaded());
            },
            trackCameraPosition:
                widget.interactive && widget.onCameraIdleLocation != null,
            onCameraIdle: _onCameraIdle,
            compassEnabled: widget.interactive,
            rotateGesturesEnabled: widget.interactive,
            scrollGesturesEnabled: widget.interactive,
            zoomGesturesEnabled: widget.interactive,
            tiltGesturesEnabled: widget.interactive,
            dragEnabled: widget.interactive,
            logoEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
          ),
          Positioned(
            right: 10,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.toch.card.withValues(alpha: .86),
                borderRadius: BorderRadius.circular(TochRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  'OpenFreeMap',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.toch.green700.withValues(alpha: .68),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCameraIdle() async {
    final callback = widget.onCameraIdleLocation;
    final controller = _controller;
    if (callback == null || controller == null) {
      return;
    }

    final position =
        controller.cameraPosition ?? await controller.queryCameraPosition();
    final target = position?.target;
    if (target == null) {
      return;
    }

    callback(
      HomeLocation(
        cityName: widget.location.cityName,
        latitude: target.latitude,
        longitude: target.longitude,
      ),
    );
  }
}
