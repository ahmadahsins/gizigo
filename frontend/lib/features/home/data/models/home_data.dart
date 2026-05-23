import 'home_category.dart';
import 'home_food_item.dart';

class HomeData {
  const HomeData({
    required this.categories,
    required this.featured,
    required this.recommendations,
    this.recommendationsError,
  });

  final List<HomeCategory> categories;
  final List<HomeFoodItem> featured;
  final List<HomeFoodItem> recommendations;
  final Object? recommendationsError;
}
