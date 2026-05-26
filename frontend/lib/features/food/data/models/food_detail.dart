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
    required this.merchant,
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
  final FoodMerchantDetail merchant;

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
    final merchantJson = _asMap(json['merchant'] ?? json['vendor']);
    final vendorName = _asString(
      json['vendor_name'],
      fallback: _asString(
        merchantJson?['name'] ?? merchantJson?['business_name'],
      ),
    );

    return FoodDetail(
      id: _asString(json['id'], fallback: _asString(json['food_id'])),
      name: _asString(json['name'], fallback: 'Untitled food'),
      description: _asString(json['description']),
      vendorName: vendorName,
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
      merchant: FoodMerchantDetail.fromJson(
        json,
        merchantJson: merchantJson,
        fallbackName: vendorName,
      ),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
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

class FoodMerchantDetail {
  const FoodMerchantDetail({
    required this.name,
    required this.email,
    required this.address,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String email;
  final String address;
  final String photoUrl;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  String displayName({String fallback = 'Merchant'}) {
    if (name.isNotEmpty) return name;
    return fallback.trim().isEmpty ? 'Merchant' : fallback;
  }

  factory FoodMerchantDetail.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? merchantJson,
    required String fallbackName,
  }) {
    final merchant = merchantJson ?? const <String, dynamic>{};
    final coordinates = FoodDetail._asMap(
      merchant['coordinates'] ?? json['merchant_coordinates'],
    );
    final lat = FoodDetail._asDouble(
      merchant['lat'] ??
          merchant['latitude'] ??
          json['merchant_lat'] ??
          json['merchant_latitude'] ??
          json['vendor_lat'] ??
          json['vendor_latitude'] ??
          coordinates?['lat'] ??
          coordinates?['latitude'],
    );
    final lng = FoodDetail._asDouble(
      merchant['lng'] ??
          merchant['longitude'] ??
          json['merchant_lng'] ??
          json['merchant_longitude'] ??
          json['vendor_lng'] ??
          json['vendor_longitude'] ??
          coordinates?['lng'] ??
          coordinates?['longitude'],
    );

    return FoodMerchantDetail(
      name: FoodDetail._asString(
        merchant['name'] ?? merchant['business_name'],
        fallback: FoodDetail._asString(
          json['merchant_name'] ?? json['business_name'],
          fallback: fallbackName,
        ),
      ),
      email: FoodDetail._asString(
        merchant['email'] ?? merchant['business_email'],
        fallback: FoodDetail._asString(
          json['merchant_email'] ??
              json['business_email'] ??
              json['vendor_email'],
        ),
      ),
      address: FoodDetail._asString(
        merchant['address'],
        fallback: FoodDetail._asString(
          json['merchant_address'] ??
              json['business_address'] ??
              json['vendor_address'] ??
              json['address'],
        ),
      ),
      photoUrl: FoodDetail._asString(
        merchant['photo_url'] ??
            merchant['image_url'] ??
            merchant['avatar_url'],
        fallback: FoodDetail._asString(
          json['merchant_photo_url'] ??
              json['merchant_image_url'] ??
              json['vendor_photo_url'] ??
              json['vendor_image_url'],
        ),
      ),
      latitude: lat,
      longitude: lng,
    );
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
