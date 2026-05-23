import '../../../../core/models/nutrition_grade.dart';
import '../../../../core/utils/currency_formatter.dart';

class SearchFoodItem {
  const SearchFoodItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.basePrice,
    required this.nutritionGrade,
    required this.distanceKm,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final int? basePrice;
  final String nutritionGrade;
  final double? distanceKm;
  final String imageUrl;

  String get price => formatRupiah(basePrice);

  String get ratingText => NutritionGrade.labelFor(nutritionGrade);

  factory SearchFoodItem.fromJson(Map<String, dynamic> json) {
    final vendorName = _asString(json['vendor_name']);
    final description = _asString(json['description']);
    final distance = _asDouble(json['distance_in_km']);

    return SearchFoodItem(
      id: _asString(json['id'], fallback: _asString(json['food_id'])),
      title: _asString(json['name'], fallback: 'Untitled food'),
      subtitle: _subtitleFor(vendorName, description, distance),
      basePrice: _asInt(json['base_price']),
      nutritionGrade: _asString(json['nutrition_grade']),
      distanceKm: distance,
      imageUrl: _asString(
        json['image_url'],
        fallback: _asString(json['photo_url']),
      ),
    );
  }

  static String _subtitleFor(
    String vendorName,
    String description,
    double? distance,
  ) {
    if (vendorName.isNotEmpty && distance != null) {
      return '$vendorName - ${distance.toStringAsFixed(1)} km';
    }
    if (vendorName.isNotEmpty) return vendorName;
    return description;
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
