import '../../../../core/models/nutrition_grade.dart';
import '../../../../core/utils/currency_formatter.dart';

class HomeFoodItem {
  const HomeFoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.vendorName,
    required this.imageUrl,
    required this.basePrice,
    required this.nutritionGrade,
    required this.distanceInKm,
  });

  final String id;
  final String name;
  final String description;
  final String vendorName;
  final String imageUrl;
  final int? basePrice;
  final String nutritionGrade;
  final double? distanceInKm;

  String get ratingText => NutritionGrade.labelFor(nutritionGrade);

  String get formattedPrice => formatRupiah(basePrice);

  String get subtitle {
    if (vendorName.isNotEmpty && distanceInKm != null) {
      return '$vendorName - ${distanceInKm!.toStringAsFixed(1)} km';
    }
    if (vendorName.isNotEmpty) return vendorName;
    return description;
  }

  factory HomeFoodItem.fromJson(Map<String, dynamic> json) {
    return HomeFoodItem(
      id: _asString(json['id'], fallback: _asString(json['food_id'])),
      name: _asString(json['name'], fallback: 'Untitled food'),
      description: _asString(json['description']),
      vendorName: _asString(json['vendor_name']),
      imageUrl: _asString(
        json['image_url'],
        fallback: _asString(json['photo_url']),
      ),
      basePrice: _asInt(json['base_price']),
      nutritionGrade: _asString(json['nutrition_grade']),
      distanceInKm: _asDouble(json['distance_in_km']),
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

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
