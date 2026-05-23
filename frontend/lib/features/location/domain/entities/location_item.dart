class LocationItem {
  const LocationItem({
    required this.name,
    required this.address,
    required this.distanceLabel,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final String distanceLabel;
  final double latitude;
  final double longitude;

  double? get distanceKm {
    final normalized = distanceLabel
        .toLowerCase()
        .replaceAll('km', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(normalized);
  }

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    final lat = _asDouble(json['lat'] ?? json['latitude']);
    final lng = _asDouble(json['lng'] ?? json['longitude']);
    final distanceKm = _asDouble(json['distance_km']);

    return LocationItem(
      name: _asString(
        json['label'] ?? json['name'],
        fallback: 'Saved location',
      ),
      address: _asString(json['address']),
      distanceLabel: distanceKm == null
          ? _asString(json['distanceLabel'], fallback: '0.0km')
          : '${distanceKm.toStringAsFixed(1)}km',
      latitude: lat ?? 0,
      longitude: lng ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'distanceLabel': distanceLabel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
