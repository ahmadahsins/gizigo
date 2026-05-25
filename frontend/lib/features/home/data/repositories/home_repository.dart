import '../datasources/home_remote_data_source.dart';
import '../models/home_category.dart';
import '../models/home_data.dart';

class HomeRepository {
  HomeRepository(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  List<HomeCategory> get localCategories => HomeCategory.defaultCategories;

  Future<List<HomeCategory>> getCategories() async {
    try {
      final categories = await _remoteDataSource.getCategories();
      return HomeCategory.withDefaultCategories(categories);
    } catch (_) {}

    return HomeCategory.defaultCategories;
  }

  Future<HomeData> getHomeData({double? lat, double? lng}) async {
    try {
      final categories = await getCategories();
      final recommendations = await _remoteDataSource.getRecommendations(
        lat: lat,
        lng: lng,
      );

      return HomeData(
        categories: categories,
        featured: recommendations.featured,
        recommendations: recommendations.recommendations,
      );
    } catch (error) {
      return HomeData(
        categories: HomeCategory.defaultCategories,
        featured: const [],
        recommendations: const [],
        recommendationsError: error,
      );
    }
  }
}
