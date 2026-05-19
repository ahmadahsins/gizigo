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
}
