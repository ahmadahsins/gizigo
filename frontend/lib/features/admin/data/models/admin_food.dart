import '../../../../core/utils/currency_formatter.dart';

class AdminFood {
  const AdminFood({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int? basePrice;
  final bool isAvailable;

  String get formattedPrice => formatRupiah(basePrice);

  AdminFood copyWith({bool? isAvailable}) {
    return AdminFood(
      id: id,
      name: name,
      imageUrl: imageUrl,
      basePrice: basePrice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory AdminFood.fromJson(Map<String, dynamic> json) {
    return AdminFood(
      id: _asString(json['id'], fallback: _asString(json['food_id'])),
      name: _asString(json['name'], fallback: 'Untitled menu'),
      imageUrl: _asString(
        json['image_url'],
        fallback: _asString(json['photo_url']),
      ),
      basePrice: _asInt(json['base_price']),
      isAvailable: _asBool(json['is_available'], fallback: true),
    );
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
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
}
