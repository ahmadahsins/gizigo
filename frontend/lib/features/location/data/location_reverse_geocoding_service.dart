import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class ReverseGeocodedLocation {
  const ReverseGeocodedLocation({required this.name, required this.address});

  final String name;
  final String address;
}

class ForwardGeocodedLocation {
  const ForwardGeocodedLocation({
    required this.name,
    required this.address,
    required this.point,
  });

  final String name;
  final String address;
  final LatLng point;
}

class LocationReverseGeocodingService {
  LocationReverseGeocodingService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'GiziGo/1.0 Flutter mobile app',
              },
            ),
          );

  final Dio _dio;

  Future<ReverseGeocodedLocation> reverseGeocode(
    LatLng point, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {
        'format': 'jsonv2',
        'lat': point.latitude.toStringAsFixed(7),
        'lon': point.longitude.toStringAsFixed(7),
        'zoom': 18,
        'addressdetails': 1,
      },
      options: Options(headers: {'Accept-Language': 'id'}),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Reverse geocoding returned an empty response.');
    }

    final fallbackAddress = _formatCoordinates(point);
    final address = _readString(data, 'display_name') ?? fallbackAddress;

    return ReverseGeocodedLocation(
      name: _extractPlaceName(data) ?? 'Pinned location',
      address: address,
    );
  }

  Future<List<ForwardGeocodedLocation>> searchLocations(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'format': 'jsonv2',
        'q': normalizedQuery,
        'limit': 6,
        'addressdetails': 1,
        'countrycodes': 'id',
      },
      options: Options(headers: {'Accept-Language': 'id'}),
      cancelToken: cancelToken,
    );

    final places = response.data;
    if (places == null || places.isEmpty) return const [];

    return places
        .whereType<Map>()
        .map((place) => _parseForwardGeocodedLocation(place, normalizedQuery))
        .whereType<ForwardGeocodedLocation>()
        .toList();
  }

  static ForwardGeocodedLocation? _parseForwardGeocodedLocation(
    Map<dynamic, dynamic> rawPlace,
    String fallbackName,
  ) {
    final place = Map<String, dynamic>.from(rawPlace);
    final latitude = double.tryParse(_readString(place, 'lat') ?? '');
    final longitude = double.tryParse(_readString(place, 'lon') ?? '');
    if (latitude == null || longitude == null) return null;

    final point = LatLng(latitude, longitude);
    final address =
        _readString(place, 'display_name') ?? _formatCoordinates(point);

    return ForwardGeocodedLocation(
      name: _extractPlaceName(place) ?? fallbackName,
      address: address,
      point: point,
    );
  }

  static String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
  }

  static String? _extractPlaceName(Map<String, dynamic> data) {
    final directName = _readString(data, 'name');
    if (directName != null) return directName;

    final rawAddress = data['address'];
    if (rawAddress is! Map) return null;

    for (final key in const [
      'amenity',
      'building',
      'shop',
      'tourism',
      'leisure',
      'road',
      'neighbourhood',
      'suburb',
      'village',
      'town',
      'city',
      'county',
      'state',
    ]) {
      final value = rawAddress[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
