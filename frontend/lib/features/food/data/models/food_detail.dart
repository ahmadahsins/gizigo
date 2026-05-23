import '../../../../core/models/nutrition_grade.dart';
import '../../../../core/utils/currency_formatter.dart';

class FoodDetail {
  const FoodDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.vendorName,
    required this.imageUrl,
    required this.basePrice,
    required this.nutritionGrade,
    required this.foodCategory,
    required this.healthLabels,
    required this.nutritionalInfo,
    required this.priceComparisons,
  });

  final String id;
  final String name;
  final String description;
  final String vendorName;
  final String imageUrl;
  final int? basePrice;
  final String nutritionGrade;
  final String foodCategory;
  final List<String> healthLabels;
  final FoodNutritionalInfo? nutritionalInfo;
  final List<FoodPriceComparison> priceComparisons;

  NutritionGrade? get grade => NutritionGrade.tryParse(nutritionGrade);

  String get ratingText => NutritionGrade.labelFor(nutritionGrade);

  String get formattedPrice => formatRupiah(basePrice);

  List<String> get displayLabels {
    if (healthLabels.isNotEmpty) return healthLabels;
    return [ratingText];
  }

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    final comparisons = json['price_comparisons'];
    final labels = json['health_labels'];
    final nutritionalInfo = json['nutritional_info'];

    return FoodDetail(
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
      foodCategory: _asString(json['food_category']),
      healthLabels: labels is List
          ? labels
                .map((label) => label.toString().trim())
                .where((label) => label.isNotEmpty)
                .toList(growable: false)
          : const [],
      nutritionalInfo: nutritionalInfo is Map
          ? FoodNutritionalInfo.fromJson(
              Map<String, dynamic>.from(nutritionalInfo),
            )
          : null,
      priceComparisons: comparisons is List
          ? comparisons
                .whereType<Map>()
                .map(
                  (item) => FoodPriceComparison.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
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
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class FoodNutritionalInfo {
  const FoodNutritionalInfo({
    this.calories,
    this.proteinG,
    this.fatG,
    this.carbG,
  });

  final double? calories;
  final double? proteinG;
  final double? fatG;
  final double? carbG;

  bool get hasAnyValue =>
      calories != null || proteinG != null || fatG != null || carbG != null;

  factory FoodNutritionalInfo.fromJson(Map<String, dynamic> json) {
    return FoodNutritionalInfo(
      calories: FoodDetail._asDouble(json['calories']),
      proteinG: FoodDetail._asDouble(json['protein_g']),
      fatG: FoodDetail._asDouble(json['fat_g']),
      carbG: FoodDetail._asDouble(json['carb_g']),
    );
  }
}

class FoodPriceComparison {
  const FoodPriceComparison({
    required this.platformKey,
    required this.platform,
    required this.price,
    required this.basePrice,
    required this.orderUrl,
  });

  final String platformKey;
  final String platform;
  final int? price;
  final int? basePrice;
  final String orderUrl;

  String get formattedPrice => formatRupiah(price ?? basePrice);

  factory FoodPriceComparison.fromJson(Map<String, dynamic> json) {
    return FoodPriceComparison(
      platformKey: FoodDetail._asString(json['platform_key']),
      platform: FoodDetail._asString(json['platform'], fallback: 'Food app'),
      price: FoodDetail._asInt(json['price']),
      basePrice: FoodDetail._asInt(json['base_price']),
      orderUrl: FoodDetail._asString(json['order_url']),
    );
  }
}
