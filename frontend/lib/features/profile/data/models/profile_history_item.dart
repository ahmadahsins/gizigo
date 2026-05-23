import '../../../../core/models/nutrition_grade.dart';
import '../../../../core/utils/currency_formatter.dart';

class ProfileHistoryItem {
  const ProfileHistoryItem({
    required this.viewedAt,
    required this.foodId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.nutritionGrade,
  });

  final DateTime? viewedAt;
  final String foodId;
  final String name;
  final String description;
  final String imageUrl;
  final int? basePrice;
  final String nutritionGrade;

  String get formattedPrice => formatRupiah(basePrice);

  String get ratingText => NutritionGrade.labelFor(nutritionGrade);

  factory ProfileHistoryItem.fromJson(Map<String, dynamic> json) {
    final food = json['food'];
    final foodJson = food is Map ? Map<String, dynamic>.from(food) : json;

    return ProfileHistoryItem(
      viewedAt: DateTime.tryParse(_asString(json['viewed_at'])),
      foodId: _asString(foodJson['id'] ?? foodJson['food_id']),
      name: _asString(foodJson['name'], fallback: 'Untitled food'),
      description: _asString(foodJson['description']),
      imageUrl: _asString(
        foodJson['image_url'],
        fallback: _asString(foodJson['photo_url']),
      ),
      basePrice: _asInt(foodJson['base_price']),
      nutritionGrade: _asString(foodJson['nutrition_grade']),
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
}
