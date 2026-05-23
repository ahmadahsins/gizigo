import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/location_item.dart';

class LocationRemoteDataSource {
  LocationRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<LocationItem>> getRecentLocations() async {
    final response = await _client.get(ApiConstants.usersRecentLocations);
    final data = response.data;
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((item) => LocationItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> saveRecentLocation(LocationItem location) {
    return _client.post(
      ApiConstants.usersRecentLocations,
      data: {
        'label': location.name,
        'address': location.address,
        'lat': location.latitude,
        'lng': location.longitude,
        if (location.distanceKm != null) 'distance_km': location.distanceKm,
      },
    );
  }
}
