import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/home_food_item.dart';

class HomeRecommendationsResponse {
  const HomeRecommendationsResponse({
    required this.featured,
    required this.recommendations,
  });

  final List<HomeFoodItem> featured;
  final List<HomeFoodItem> recommendations;
}

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._client);

  final DioClient _client;

  Future<HomeRecommendationsResponse> getRecommendations({
    double? lat,
    double? lng,
  }) async {
    final response = await _client.get(
      ApiConstants.foodRecommendations,
      queryParameters: {
        'featured_limit': 1,
        'limit': 15,
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid recommendations response.');
    }

    return HomeRecommendationsResponse(
      featured: _listFrom(
        data['featured'],
      ).map(HomeFoodItem.fromJson).toList(growable: false),
      recommendations: _listFrom(
        data['recommendations'],
      ).map(HomeFoodItem.fromJson).toList(growable: false),
    );
  }

  List<Map<String, dynamic>> _listFrom(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
