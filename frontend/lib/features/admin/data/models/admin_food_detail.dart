class AdminFoodDetail {
  const AdminFoodDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.foodCategory,
    required this.healthLabels,
    required this.isAvailable,
    required this.ingredients,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int? basePrice;
  final String foodCategory;
  final List<String> healthLabels;
  final bool isAvailable;
  final List<AdminFoodIngredient> ingredients;

  factory AdminFoodDetail.fromJson(Map<String, dynamic> json) {
    final labels = json['health_labels'];
    final ingredients = json['ingredients'] ?? json['recipe_ingredients'];

    return AdminFoodDetail(
      id: _asString(json['id'], fallback: _asString(json['food_id'])),
      name: _asString(json['name'], fallback: 'Untitled menu'),
      description: _asString(json['description']),
      imageUrl: _asString(
        json['image_url'],
        fallback: _asString(json['photo_url']),
      ),
      basePrice: _asInt(json['base_price']),
      foodCategory: _asString(json['food_category']),
      healthLabels: labels is List
          ? labels
                .map((label) => label.toString().trim())
                .where((label) => label.isNotEmpty)
                .toList(growable: false)
          : const [],
      isAvailable: _asBool(json['is_available'], fallback: true),
      ingredients: ingredients is List
          ? ingredients
                .whereType<Map>()
                .map(
                  (item) => AdminFoodIngredient.fromJson(
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

class AdminFoodIngredient {
  const AdminFoodIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final String quantity;
  final String unit;

  factory AdminFoodIngredient.fromJson(Map<String, dynamic> json) {
    return AdminFoodIngredient(
      name: AdminFoodDetail._asString(
        json['name'] ?? json['ingredient'] ?? json['ingredient_name'],
      ),
      quantity: AdminFoodDetail._asString(
        json['quantity'] ?? json['amount'] ?? json['qty'],
      ),
      unit: AdminFoodDetail._asString(json['unit'], fallback: 'qty'),
    );
  }
}
