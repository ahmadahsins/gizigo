class AdminMerchant {
  const AdminMerchant({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    this.email = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final bool isActive;
  final String email;
  final double? latitude;
  final double? longitude;

  factory AdminMerchant.fromJson(Map<String, dynamic> json) {
    return AdminMerchant(
      id: _asString(
        json['id'] ?? json['merchant_id'] ?? json['uid'],
        fallback: _asString(json['name']),
      ),
      name: _asString(json['name'], fallback: 'Unnamed merchant'),
      address: _asString(json['address']),
      isActive: _asBool(json['is_active'], fallback: true),
      email: _asString(json['email'] ?? json['business_email']),
      latitude: _asDouble(json['lat'] ?? json['latitude']),
      longitude: _asDouble(json['lng'] ?? json['longitude']),
    );
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static bool isDeletedJson(Map<String, dynamic> json) {
    return _asBool(json['is_deleted'] ?? json['deleted'], fallback: false) ||
        json['deleted_at'] != null ||
        _asString(json['status']).toLowerCase() == 'deleted';
  }

  static bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return switch (text) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => fallback,
    };
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
