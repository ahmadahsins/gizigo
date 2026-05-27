import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/admin_food.dart';
import 'models/admin_food_detail.dart';
import 'models/admin_merchant.dart';

class AdminMerchantListResponse {
  const AdminMerchantListResponse({required this.items, required this.total});

  final List<AdminMerchant> items;
  final int total;
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.merchants,
    required this.totalMerchants,
    required this.totalActiveMenus,
    required this.totalInactiveMenus,
  });

  final List<AdminMerchant> merchants;
  final int totalMerchants;
  final int totalActiveMenus;
  final int totalInactiveMenus;
}

class AdminRemoteDataSource {
  AdminRemoteDataSource(this._client);

  final DioClient _client;

  Future<AdminDashboardData> getDashboardData({
    Set<String> excludedMerchantIds = const {},
  }) async {
    final merchants = await getMerchants(limit: 50, isActive: true);
    final visibleMerchants = merchants.items
        .where((merchant) => !excludedMerchantIds.contains(merchant.id))
        .toList(growable: false);
    final merchantFoods = await Future.wait(
      visibleMerchants.map((merchant) => _getMerchantFoodsOrEmpty(merchant.id)),
    );
    final foods = merchantFoods.expand((items) => items).toList();
    final totalActiveMenus = foods.where((food) => food.isAvailable).length;

    return AdminDashboardData(
      merchants: visibleMerchants,
      totalMerchants: visibleMerchants.length,
      totalActiveMenus: totalActiveMenus,
      totalInactiveMenus: foods.length - totalActiveMenus,
    );
  }

  Future<List<AdminFood>> _getMerchantFoodsOrEmpty(String merchantId) async {
    try {
      return await getMerchantFoods(merchantId);
    } catch (_) {
      return const [];
    }
  }

  Future<AdminMerchantListResponse> getMerchants({
    int page = 1,
    int limit = 20,
    bool? isActive,
  }) async {
    final response = await _client.get(
      ApiConstants.adminMerchants,
      queryParameters: {'page': page, 'limit': limit, 'is_active': ?isActive},
    );

    final data = response.data;
    final itemJson = _itemsFrom(data)
        .where((item) => !AdminMerchant.isDeletedJson(item))
        .toList(growable: false);
    final items = itemJson.map(AdminMerchant.fromJson).toList();

    return AdminMerchantListResponse(
      items: items,
      total: _totalFrom(data, fallback: items.length),
    );
  }

  Future<List<AdminFood>> getMerchantFoods(String merchantId) async {
    final response = await _client.get(
      ApiConstants.adminMerchantFoods(merchantId),
      queryParameters: const {'page': 1, 'limit': 100},
    );

    return _itemsFrom(response.data).map(AdminFood.fromJson).toList();
  }

  Future<AdminMerchant> getMerchant(String merchantId) async {
    final response = await _client.get(
      ApiConstants.adminMerchantDetails(merchantId),
    );
    final data = response.data;

    if (data is Map) {
      final merchantJson = _firstMap(data, const ['merchant', 'data', 'item']);
      return AdminMerchant.fromJson(
        merchantJson ?? Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException('Invalid admin merchant detail response.');
  }

  Future<AdminFoodDetail> getFoodDetail(String foodId) async {
    final response = await _client.get(ApiConstants.adminFoodDetails(foodId));
    final data = response.data;

    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      return AdminFoodDetail.fromJson(
        foodJson ?? Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException('Invalid admin food detail response.');
  }

  Future<AdminMerchant> getOwnMerchant() async {
    final response = await _client.get(ApiConstants.merchantMe);
    final data = response.data;

    if (data is Map) {
      final merchantJson = _firstMap(data, const ['merchant', 'data', 'item']);
      return AdminMerchant.fromJson(
        merchantJson ?? Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException('Invalid merchant profile response.');
  }

  Future<AdminMerchant> updateOwnMerchant({
    required String id,
    required String name,
    required String address,
    String email = '',
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.patch(
      ApiConstants.merchantMe,
      data: {
        'name': name,
        'address': address,
        if (latitude != null && longitude != null) ...{
          'lat': latitude,
          'lng': longitude,
        },
      },
    );

    return _merchantFromResponse(
      response.data,
      fallback: AdminMerchant(
        id: id,
        name: name,
        address: address,
        isActive: true,
        email: email,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<List<AdminFood>> getOwnFoods() async {
    final response = await _client.get(
      ApiConstants.merchantFoods,
      queryParameters: const {'page': 1, 'limit': 100},
    );

    return _itemsFrom(response.data).map(AdminFood.fromJson).toList();
  }

  Future<AdminFoodDetail> getOwnFoodDetail(String foodId) async {
    final response = await _client.get(
      ApiConstants.merchantFoodDetails(foodId),
    );
    final data = response.data;

    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      return AdminFoodDetail.fromJson(
        foodJson ?? Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException('Invalid merchant food detail response.');
  }

  Future<AdminMerchant> createMerchant({
    required String name,
    required String email,
    required String password,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.post(
      ApiConstants.adminMerchants,
      data: {
        'name': name,
        'business_email': email,
        'password': password,
        'address': address,
        'lat': latitude,
        'lng': longitude,
      },
    );

    return _merchantFromResponse(
      response.data,
      fallback: AdminMerchant(
        id: '',
        name: name,
        address: address,
        isActive: true,
        email: email,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<AdminMerchant> updateMerchant({
    required String id,
    required String name,
    required String address,
    required bool isActive,
    String email = '',
    String? password,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.put(
      ApiConstants.adminMerchantDetails(id),
      data: {
        'name': name,
        if (email.trim().isNotEmpty) 'business_email': email,
        if ((password ?? '').trim().isNotEmpty) 'password': password!.trim(),
        'address': address,
        'is_active': isActive,
        if (latitude != null && longitude != null) ...{
          'lat': latitude,
          'lng': longitude,
        },
      },
    );

    return _merchantFromResponse(
      response.data,
      fallback: AdminMerchant(
        id: id,
        name: name,
        address: address,
        isActive: isActive,
        email: email,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<bool> deleteMerchant(String merchantId) async {
    await _client.delete(ApiConstants.adminMerchantDetails(merchantId));
    return true;
  }

  Future<void> updateFoodAvailability({
    required String foodId,
    required bool isAvailable,
  }) async {
    await _client.put(
      ApiConstants.adminFoodDetails(foodId),
      data: {'is_available': isAvailable},
    );
  }

  Future<void> updateOwnFoodAvailability({
    required String foodId,
    required bool isAvailable,
  }) async {
    await _client.put(
      ApiConstants.merchantFoodDetails(foodId),
      data: {'is_available': isAvailable},
    );
  }

  Future<void> deleteFood(String foodId) async {
    await _client.delete(ApiConstants.adminFoodDetails(foodId));
  }

  Future<void> deleteOwnFood(String foodId) async {
    await _client.delete(ApiConstants.merchantFoodDetails(foodId));
  }

  Future<AdminFoodDetail> updateFood({
    required String foodId,
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    List<Map<String, Object>> recipeIngredients = const [],
    String? gofoodLink,
    String? grabfoodLink,
    String? shopeefoodLink,
    Uint8List? photoBytes,
    String? photoFilename,
    String currentImageUrl = '',
  }) async {
    final response = await _client.put(
      ApiConstants.adminFoodDetails(foodId),
      data: _foodPayload(
        name: name,
        description: description,
        foodCategory: foodCategory,
        healthLabels: healthLabels,
        basePrice: basePrice,
        isAvailable: isAvailable,
        recipeIngredients: recipeIngredients,
        gofoodLink: gofoodLink,
        grabfoodLink: grabfoodLink,
        shopeefoodLink: shopeefoodLink,
      ),
    );

    if (photoBytes != null && photoBytes.isNotEmpty) {
      await _tryUploadFoodPhoto(
        foodId: foodId,
        bytes: photoBytes,
        filename: photoFilename ?? 'menu-photo.jpg',
        photoPathBuilder: ApiConstants.adminFoodPhoto,
      );
    }

    final data = response.data;
    final fallback = AdminFoodDetail(
      id: foodId,
      name: name,
      description: description,
      imageUrl: currentImageUrl,
      basePrice: basePrice,
      foodCategory: foodCategory,
      healthLabels: healthLabels,
      isAvailable: isAvailable,
      ingredients: recipeIngredients.map((e) => AdminFoodIngredient(
        name: e['name'] as String? ?? '',
        quantity: e['amount']?.toString() ?? '',
        unit: e['unit'] as String? ?? '',
      )).toList(),
      gofoodLink: gofoodLink ?? '',
      grabfoodLink: grabfoodLink ?? '',
      shopeefoodLink: shopeefoodLink ?? '',
    );
    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      final source = foodJson ?? Map<String, dynamic>.from(data);
      if (_isFoodDetailJson(source)) {
        final parsed = AdminFoodDetail.fromJson(source);
        return AdminFoodDetail(
          id: parsed.id.isEmpty ? fallback.id : parsed.id,
          name: source.containsKey('name') ? parsed.name : fallback.name,
          description: source.containsKey('description') ? parsed.description : fallback.description,
          imageUrl: parsed.imageUrl.isEmpty ? fallback.imageUrl : parsed.imageUrl,
          basePrice: source.containsKey('base_price') ? parsed.basePrice : fallback.basePrice,
          foodCategory: source.containsKey('food_category') ? parsed.foodCategory : fallback.foodCategory,
          healthLabels: source.containsKey('health_labels') ? parsed.healthLabels : fallback.healthLabels,
          isAvailable: source.containsKey('is_available') ? parsed.isAvailable : fallback.isAvailable,
          ingredients: source.containsKey('recipe') || source.containsKey('ingredients') || source.containsKey('recipe_ingredients') ? parsed.ingredients : fallback.ingredients,
          gofoodLink: source.containsKey('comparison_data') || source.containsKey('gofood_link') ? parsed.gofoodLink : fallback.gofoodLink,
          grabfoodLink: source.containsKey('comparison_data') || source.containsKey('grabfood_link') ? parsed.grabfoodLink : fallback.grabfoodLink,
          shopeefoodLink: source.containsKey('comparison_data') || source.containsKey('shopeefood_link') ? parsed.shopeefoodLink : fallback.shopeefoodLink,
        );
      }
    }

    return fallback;
  }

  Future<AdminFoodDetail> updateOwnFood({
    required String foodId,
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    List<Map<String, Object>> recipeIngredients = const [],
    String? gofoodLink,
    String? grabfoodLink,
    String? shopeefoodLink,
    Uint8List? photoBytes,
    String? photoFilename,
    String currentImageUrl = '',
  }) async {
    final response = await _client.put(
      ApiConstants.merchantFoodDetails(foodId),
      data: _foodPayload(
        name: name,
        description: description,
        foodCategory: foodCategory,
        healthLabels: healthLabels,
        basePrice: basePrice,
        isAvailable: isAvailable,
        recipeIngredients: recipeIngredients,
        gofoodLink: gofoodLink,
        grabfoodLink: grabfoodLink,
        shopeefoodLink: shopeefoodLink,
      ),
    );

    if (photoBytes != null && photoBytes.isNotEmpty) {
      await _tryUploadFoodPhoto(
        foodId: foodId,
        bytes: photoBytes,
        filename: photoFilename ?? 'menu-photo.jpg',
        photoPathBuilder: ApiConstants.merchantFoodPhoto,
      );
    }

    final data = response.data;
    final fallback = AdminFoodDetail(
      id: foodId,
      name: name,
      description: description,
      imageUrl: currentImageUrl,
      basePrice: basePrice,
      foodCategory: foodCategory,
      healthLabels: healthLabels,
      isAvailable: isAvailable,
      ingredients: recipeIngredients.map((e) => AdminFoodIngredient(
        name: e['name'] as String? ?? '',
        quantity: e['amount']?.toString() ?? '',
        unit: e['unit'] as String? ?? '',
      )).toList(),
      gofoodLink: gofoodLink ?? '',
      grabfoodLink: grabfoodLink ?? '',
      shopeefoodLink: shopeefoodLink ?? '',
    );
    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      final source = foodJson ?? Map<String, dynamic>.from(data);
      if (_isFoodDetailJson(source)) {
        final parsed = AdminFoodDetail.fromJson(source);
        return AdminFoodDetail(
          id: parsed.id.isEmpty ? fallback.id : parsed.id,
          name: source.containsKey('name') ? parsed.name : fallback.name,
          description: source.containsKey('description') ? parsed.description : fallback.description,
          imageUrl: parsed.imageUrl.isEmpty ? fallback.imageUrl : parsed.imageUrl,
          basePrice: source.containsKey('base_price') ? parsed.basePrice : fallback.basePrice,
          foodCategory: source.containsKey('food_category') ? parsed.foodCategory : fallback.foodCategory,
          healthLabels: source.containsKey('health_labels') ? parsed.healthLabels : fallback.healthLabels,
          isAvailable: source.containsKey('is_available') ? parsed.isAvailable : fallback.isAvailable,
          ingredients: source.containsKey('recipe') || source.containsKey('ingredients') || source.containsKey('recipe_ingredients') ? parsed.ingredients : fallback.ingredients,
          gofoodLink: source.containsKey('comparison_data') ? parsed.gofoodLink : fallback.gofoodLink,
          grabfoodLink: source.containsKey('comparison_data') ? parsed.grabfoodLink : fallback.grabfoodLink,
          shopeefoodLink: source.containsKey('comparison_data') ? parsed.shopeefoodLink : fallback.shopeefoodLink,
        );
      }
    }

    return fallback;
  }

  Future<AdminFood> createFood({
    required String merchantId,
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    required List<Map<String, Object>> recipeIngredients,
    String? gofoodLink,
    String? grabfoodLink,
    String? shopeefoodLink,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.post(
      ApiConstants.adminMerchantFoods(merchantId),
      data: _foodPayload(
        name: name,
        description: description,
        foodCategory: foodCategory,
        healthLabels: healthLabels,
        basePrice: basePrice,
        isAvailable: isAvailable,
        recipeIngredients: recipeIngredients,
        gofoodLink: gofoodLink,
        grabfoodLink: grabfoodLink,
        shopeefoodLink: shopeefoodLink,
      ),
    );

    final data = response.data;
    final id = data is Map ? _asString(data['id'] ?? data['food_id']) : '';

    if (id.isNotEmpty && photoBytes != null && photoBytes.isNotEmpty) {
      await _tryUploadFoodPhoto(
        foodId: id,
        bytes: photoBytes,
        filename: photoFilename ?? 'menu-photo.jpg',
        photoPathBuilder: (foodId) =>
            ApiConstants.adminMerchantFoodPhoto(merchantId, foodId),
      );
    }

    return AdminFood(
      id: id,
      name: name,
      imageUrl: '',
      basePrice: basePrice,
      isAvailable: isAvailable,
    );
  }

  Future<AdminFood> createOwnFood({
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    required List<Map<String, Object>> recipeIngredients,
    String? gofoodLink,
    String? grabfoodLink,
    String? shopeefoodLink,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.post(
      ApiConstants.merchantFoods,
      data: _foodPayload(
        name: name,
        description: description,
        foodCategory: foodCategory,
        healthLabels: healthLabels,
        basePrice: basePrice,
        isAvailable: isAvailable,
        recipeIngredients: recipeIngredients,
        gofoodLink: gofoodLink,
        grabfoodLink: grabfoodLink,
        shopeefoodLink: shopeefoodLink,
      ),
    );

    final data = response.data;
    final foodJson = data is Map
        ? _firstMap(data, const ['food', 'data', 'item'])
        : null;
    final id = data is Map
        ? _asString(
            foodJson?['id'] ??
                foodJson?['food_id'] ??
                data['id'] ??
                data['food_id'],
          )
        : '';

    if (id.isNotEmpty && photoBytes != null && photoBytes.isNotEmpty) {
      await _tryUploadFoodPhoto(
        foodId: id,
        bytes: photoBytes,
        filename: photoFilename ?? 'menu-photo.jpg',
        photoPathBuilder: ApiConstants.merchantFoodPhoto,
      );
    }

    if (foodJson != null) return AdminFood.fromJson(foodJson);

    return AdminFood(
      id: id,
      name: name,
      imageUrl: '',
      basePrice: basePrice,
      isAvailable: isAvailable,
    );
  }

  Future<void> _tryUploadFoodPhoto({
    required String foodId,
    required Uint8List bytes,
    required String filename,
    required String Function(String id) photoPathBuilder,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      await _client.post(photoPathBuilder(foodId), data: formData);
    } catch (_) {
      // Photo upload may be unavailable on older deployments, so creation should
      // still succeed and the refreshed list can show the default image.
    }
  }

  Map<String, Object> _foodPayload({
    required String name,
    required String description,
    required String foodCategory,
    required List<String> healthLabels,
    required int basePrice,
    required bool isAvailable,
    required List<Map<String, Object>> recipeIngredients,
    String? gofoodLink,
    String? grabfoodLink,
    String? shopeefoodLink,
  }) {
    final Map<String, dynamic> comparisonData = {};
    if (gofoodLink != null && gofoodLink.isNotEmpty) {
      comparisonData['gofood'] = {'url': gofoodLink};
    }
    if (grabfoodLink != null && grabfoodLink.isNotEmpty) {
      comparisonData['grabfood'] = {'url': grabfoodLink};
    }
    if (shopeefoodLink != null && shopeefoodLink.isNotEmpty) {
      comparisonData['shopeefood'] = {'url': shopeefoodLink};
    }

    return {
      'name': name,
      'description': description,
      'food_category': foodCategory,
      'health_labels': healthLabels,
      'base_price': basePrice,
      'is_available': isAvailable,
      if (comparisonData.isNotEmpty) 'comparison_data': comparisonData,
      if (recipeIngredients.isNotEmpty)
        'recipe': {'servings': 1, 'ingredients': recipeIngredients},
    };
  }

  bool _isFoodDetailJson(Map<String, dynamic> json) {
    return json.containsKey('name') ||
        json.containsKey('description') ||
        json.containsKey('base_price') ||
        json.containsKey('food_category') ||
        json.containsKey('image_url') ||
        json.containsKey('photo_url');
  }

  List<Map<String, dynamic>> _itemsFrom(Object? data) {
    final rawItems = switch (data) {
      {'items': final items} => items,
      {'data': final items} => items,
      List items => items,
      _ => const [],
    };

    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  AdminMerchant _merchantFromResponse(
    Object? data, {
    required AdminMerchant fallback,
  }) {
    if (data is Map) {
      final merchantJson = _firstMap(data, const ['merchant', 'data', 'item']);
      final source = merchantJson ?? Map<String, dynamic>.from(data);
      final parsed = AdminMerchant.fromJson(source);
      final hasName = _asString(source['name']).isNotEmpty;
      final hasAddress = _asString(source['address']).isNotEmpty;
      final hasEmail = _asString(
        source['email'] ?? source['business_email'],
      ).isNotEmpty;
      final hasActive = source.containsKey('is_active');

      return AdminMerchant(
        id: parsed.id.isEmpty ? fallback.id : parsed.id,
        name: hasName ? parsed.name : fallback.name,
        address: hasAddress ? parsed.address : fallback.address,
        isActive: hasActive ? parsed.isActive : fallback.isActive,
        email: hasEmail ? parsed.email : fallback.email,
        latitude: parsed.latitude ?? fallback.latitude,
        longitude: parsed.longitude ?? fallback.longitude,
      );
    }

    return fallback;
  }

  int _totalFrom(Object? data, {required int fallback}) {
    if (data is Map) {
      final total = data['total'];
      if (total is num) return total.toInt();
      final parsed = int.tryParse(total?.toString() ?? '');
      if (parsed != null) return parsed;
    }

    return fallback;
  }

  String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  Map<String, dynamic>? _firstMap(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }

    return null;
  }
}
