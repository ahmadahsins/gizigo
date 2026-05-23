import '../datasources/home_remote_data_source.dart';
import '../models/home_category.dart';
import '../models/home_data.dart';

class HomeRepository {
  HomeRepository(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  static const List<HomeCategory> _localCategories = [
    HomeCategory(
      key: 'main_course',
      title: 'Main Course',
      iconAsset: 'assets/icons/categories-menu/main-course.svg',
    ),
    HomeCategory(
      key: 'appetizers',
      title: 'Appetizers',
      iconAsset: 'assets/icons/categories-menu/appetizers.svg',
    ),
    HomeCategory(
      key: 'snacks',
      title: 'Snacks',
      iconAsset: 'assets/icons/categories-menu/snacks.svg',
    ),
    HomeCategory(
      key: 'desserts',
      title: 'Desserts',
      iconAsset: 'assets/icons/categories-menu/desserts.svg',
    ),
    HomeCategory(
      key: 'beverages',
      title: 'Beverages',
      iconAsset: 'assets/icons/categories-menu/beverages.svg',
    ),
    HomeCategory(
      key: 'breakfast',
      title: 'Breakfast',
      iconAsset: 'assets/icons/categories-menu/breakfast.svg',
    ),
    HomeCategory(
      key: 'lunch',
      title: 'Lunch',
      iconAsset: 'assets/icons/categories-menu/lunch.svg',
    ),
    HomeCategory(
      key: 'dinner',
      title: 'Dinner',
      iconAsset: 'assets/icons/categories-menu/dinner.svg',
    ),
    HomeCategory(
      key: 'salads',
      title: 'Salads',
      iconAsset: 'assets/icons/categories-menu/salads.svg',
    ),
  ];

  List<HomeCategory> get localCategories => _localCategories;

  Future<HomeData> getHomeData({double? lat, double? lng}) async {
    try {
      final recommendations = await _remoteDataSource.getRecommendations(
        lat: lat,
        lng: lng,
      );

      return HomeData(
        categories: _localCategories,
        featured: recommendations.featured,
        recommendations: recommendations.recommendations,
      );
    } catch (error) {
      return HomeData(
        categories: _localCategories,
        featured: const [],
        recommendations: const [],
        recommendationsError: error,
      );
    }
  }
}
