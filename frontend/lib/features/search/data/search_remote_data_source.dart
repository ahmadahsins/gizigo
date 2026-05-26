import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../home/data/models/home_category.dart';
import '../domain/entities/search_food_item.dart';

class SearchResultsResponse {
  const SearchResultsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<SearchFoodItem> items;
  final int total;
  final int page;
  final int totalPages;
}

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._client);

  final DioClient _client;

  Future<SearchResultsResponse> searchFoods({
    String? query,
    String? categoryKey,
    String? nutritionGrade,
    double? minPrice,
    double? maxPrice,
    double? lat,
    double? lng,
    double? maxDistanceKm,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _client.get(
      ApiConstants.foodSearch,
      queryParameters: {
        if (_hasText(query)) 'q': query!.trim(),
        if (_hasText(categoryKey)) 'food_category': categoryKey!.trim(),
        if (_hasText(nutritionGrade)) 'nutrition_grade': nutritionGrade!.trim(),
        if (minPrice != null) 'min_price': minPrice.round(),
        if (maxPrice != null) 'max_price': maxPrice.round(),
        if (lat != null && lng != null) ...{
          'lat': lat,
          'lng': lng,
          'max_distance_km': ?maxDistanceKm,
          'sort': 'distance',
        },
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid search response.');
    }

    final items = data['items'];
    return SearchResultsResponse(
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) =>
                      SearchFoodItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [],
      total: _asInt(data['total']) ?? 0,
      page: _asInt(data['page']) ?? page,
      totalPages: _asInt(data['total_pages']) ?? 1,
    );
  }

  Future<List<HomeCategory>> getCategories() async {
    final response = await _client.get(ApiConstants.metaFoodCategories);
    final data = response.data;
    if (data is! Map<String, dynamic>) return HomeCategory.defaultCategories;

    final items = data['items'];
    if (items is! List) return HomeCategory.defaultCategories;

    final categories = items
        .whereType<Map>()
        .map((item) => HomeCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return HomeCategory.withDefaultCategories(categories);
  }

  Future<SearchFoodItem?> getFeaturedFood({double? lat, double? lng}) async {
    final response = await _client.get(
      ApiConstants.foodRecommendations,
      queryParameters: {
        'featured_limit': 1,
        'limit': 1,
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return null;

    final featured = data['featured'];
    if (featured is List && featured.isNotEmpty && featured.first is Map) {
      return SearchFoodItem.fromJson(
        Map<String, dynamic>.from(featured.first as Map),
      );
    }

    final recommendations = data['recommendations'];
    if (recommendations is List &&
        recommendations.isNotEmpty &&
        recommendations.first is Map) {
      return SearchFoodItem.fromJson(
        Map<String, dynamic>.from(recommendations.first as Map),
      );
    }

    return null;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
