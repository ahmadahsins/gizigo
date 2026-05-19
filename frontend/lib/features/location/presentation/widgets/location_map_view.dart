import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/location_item.dart';

enum LocationMapPlaceType { selected }

class LocationMapPlace {
  const LocationMapPlace({required this.location, required this.type});

  final LocationItem location;
  final LocationMapPlaceType type;

  LatLng get point => LatLng(location.latitude, location.longitude);
}

class LocationMapView extends StatefulWidget {
  const LocationMapView({
    super.key,
    required this.mapController,
    required this.selectedPlace,
    required this.onMapIdle,
  });

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'id.gizigo.app';

  final MapController mapController;
  final LocationMapPlace selectedPlace;
  final ValueChanged<LatLng> onMapIdle;

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  Timer? _idleTimer;
  bool _isFlinging = false;

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.selectedPlace.point,
            initialZoom: 16,
            minZoom: 5,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapEvent: _handleMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate: LocationMapView.osmTileUrl,
              userAgentPackageName: LocationMapView.userAgentPackageName,
              maxNativeZoom: 19,
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        IgnorePointer(
          child: Semantics(
            label: 'Selected map center location',
            image: true,
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 44,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventFlingAnimationStart) {
      _isFlinging = true;
      _idleTimer?.cancel();
      return;
    }

    if (event is MapEventFlingAnimationEnd) {
      _isFlinging = false;
      widget.onMapIdle(event.camera.center);
      return;
    }

    if (event is MapEventMoveEnd) {
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(milliseconds: 80), () {
        if (!mounted || _isFlinging) return;
        widget.onMapIdle(event.camera.center);
      });
      return;
    }

    if (event is MapEventDoubleTapZoomEnd) {
      widget.onMapIdle(event.camera.center);
    }
  }
}
