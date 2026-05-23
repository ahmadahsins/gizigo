import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/location_item.dart';

class LocationStorageService {
  const LocationStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String _selectedLocationKey = 'selected_location';

  final FlutterSecureStorage _storage;

  Future<LocationItem?> readSelectedLocation() async {
    final rawLocation = await _storage.read(key: _selectedLocationKey);
    if (rawLocation == null || rawLocation.isEmpty) return null;

    try {
      final json = jsonDecode(rawLocation);
      if (json is! Map<String, dynamic>) return null;

      return LocationItem.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedLocation(LocationItem location) {
    return _storage.write(
      key: _selectedLocationKey,
      value: jsonEncode(location.toJson()),
    );
  }
}
