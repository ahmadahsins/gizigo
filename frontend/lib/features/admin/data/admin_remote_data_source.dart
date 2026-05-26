import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
    final merchants = await getMerchants(limit: 50);
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

    return AdminMerchantListResponse(items: items, total: items.length);
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
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase belum dikonfigurasi.',
      );
    }

    final secondaryApp = await Firebase.initializeApp(
      name: 'admin-merchant-create-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      await user?.updateDisplayName(name);
      final idToken = await user?.getIdToken(true);

      if (user == null || idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-token',
          message: 'Firebase token merchant tidak ditemukan.',
        );
      }

      final response =
          await Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(
                milliseconds: ApiConstants.connectionTimeout,
              ),
              receiveTimeout: const Duration(
                milliseconds: ApiConstants.receiveTimeout,
              ),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
            ),
          ).post(
            ApiConstants.signup,
            data: {
              'account_type': 'merchant',
              'merchant': {
                'name': name,
                'address': address,
                'lat': latitude,
                'lng': longitude,
              },
            },
          );

      final data = response.data;
      if (data is Map) {
        final merchantJson = _firstMap(data, const [
          'merchant',
          'data',
          'item',
        ]);
        if (merchantJson != null) {
          final merchant = AdminMerchant.fromJson(merchantJson);
          return AdminMerchant(
            id: merchant.id.isEmpty ? user.uid : merchant.id,
            name: merchant.name,
            address: merchant.address,
            isActive: merchant.isActive,
            email: merchant.email.isEmpty ? email : merchant.email,
            latitude: merchant.latitude ?? latitude,
            longitude: merchant.longitude ?? longitude,
          );
        }

        final id = _asString(data['id'] ?? data['merchant_id'] ?? data['uid']);
        if (id.isNotEmpty) {
          return AdminMerchant(
            id: id,
            name: name,
            address: address,
            isActive: true,
            email: email,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }

      return AdminMerchant(
        id: user.uid,
        name: name,
        address: address,
        isActive: true,
        email: email,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (error) {
      try {
        await secondaryAuth.currentUser?.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
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
        if (email.trim().isNotEmpty) 'email': email,
        if ((password ?? '').trim().isNotEmpty) 'password': password!.trim(),
        'address': address,
        if (latitude != null && longitude != null) ...{
          'lat': latitude,
          'lng': longitude,
        },
      },
    );

    final data = response.data;
    if (data is Map) {
      final merchantJson = _firstMap(data, const ['merchant', 'data', 'item']);
      if (merchantJson != null) return AdminMerchant.fromJson(merchantJson);

      return AdminMerchant(
        id: _asString(
          data['id'] ?? data['merchant_id'] ?? data['uid'],
          fallback: id,
        ),
        name: _asString(data['name'], fallback: name),
        address: _asString(data['address'], fallback: address),
        isActive: _asBool(data['is_active'], fallback: isActive),
        email: _asString(
          data['email'] ?? data['business_email'],
          fallback: email,
        ),
        latitude: _asDouble(data['lat'] ?? data['latitude']) ?? latitude,
        longitude: _asDouble(data['lng'] ?? data['longitude']) ?? longitude,
      );
    }

    return AdminMerchant(
      id: id,
      name: name,
      address: address,
      isActive: isActive,
      email: email,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<bool> deleteMerchant(String merchantId) async {
    await _client.delete(ApiConstants.adminMerchantDetails(merchantId));

    for (var attempt = 0; attempt < 6; attempt++) {
      await Future<void>.delayed(Duration(milliseconds: 350 + attempt * 250));

      if (await _merchantDetailIsGone(merchantId)) return true;

      final merchants = await getMerchants(limit: 100);
      final stillVisible = merchants.items.any(
        (merchant) => merchant.id == merchantId,
      );
      if (!stillVisible) return true;
    }

    return false;
  }

  Future<bool> _merchantDetailIsGone(String merchantId) async {
    try {
      await getMerchant(merchantId);
      return false;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404 || statusCode == 410) return true;

      final data = error.response?.data;
      if (data is Map) {
        final message = data['message']?.toString().toLowerCase() ?? '';
        if (message.contains('not found') ||
            message.contains('tidak ditemukan')) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
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
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.put(
      ApiConstants.adminFoodDetails(foodId),
      data: {
        'name': name,
        'description': description,
        'food_category': foodCategory,
        'health_labels': healthLabels,
        'base_price': basePrice,
        'is_available': isAvailable,
      },
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
    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      return AdminFoodDetail.fromJson(
        foodJson ?? Map<String, dynamic>.from(data),
      );
    }

    return AdminFoodDetail(
      id: foodId,
      name: name,
      description: description,
      imageUrl: '',
      basePrice: basePrice,
      foodCategory: foodCategory,
      healthLabels: healthLabels,
      isAvailable: isAvailable,
      ingredients: const [],
    );
  }

  Future<AdminFoodDetail> updateOwnFood({
    required String foodId,
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.put(
      ApiConstants.merchantFoodDetails(foodId),
      data: {
        'name': name,
        'description': description,
        'food_category': foodCategory,
        'health_labels': healthLabels,
        'base_price': basePrice,
        'is_available': isAvailable,
      },
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
    if (data is Map) {
      final foodJson = _firstMap(data, const ['food', 'data', 'item']);
      return AdminFoodDetail.fromJson(
        foodJson ?? Map<String, dynamic>.from(data),
      );
    }

    return AdminFoodDetail(
      id: foodId,
      name: name,
      description: description,
      imageUrl: '',
      basePrice: basePrice,
      foodCategory: foodCategory,
      healthLabels: healthLabels,
      isAvailable: isAvailable,
      ingredients: const [],
    );
  }

  Future<AdminFood> createFood({
    required String merchantId,
    required String name,
    required String description,
    required String foodCategory,
    required int basePrice,
    required List<String> healthLabels,
    required bool isAvailable,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.post(
      ApiConstants.adminFoods,
      data: {
        'name': name,
        'description': description,
        'food_category': foodCategory,
        'health_labels': healthLabels,
        'base_price': basePrice,
        'merchant_id': merchantId,
        'is_available': isAvailable,
      },
    );

    final data = response.data;
    final id = data is Map ? _asString(data['id'] ?? data['food_id']) : '';

    if (id.isNotEmpty && photoBytes != null && photoBytes.isNotEmpty) {
      await _tryUploadFoodPhoto(
        foodId: id,
        bytes: photoBytes,
        filename: photoFilename ?? 'menu-photo.jpg',
        photoPathBuilder: ApiConstants.adminFoodPhoto,
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
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final response = await _client.post(
      ApiConstants.merchantFoods,
      data: {
        'name': name,
        'description': description,
        'food_category': foodCategory,
        'health_labels': healthLabels,
        'base_price': basePrice,
        'is_available': isAvailable,
      },
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

  String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return switch (text) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => fallback,
    };
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? _firstMap(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }

    return null;
  }
}
