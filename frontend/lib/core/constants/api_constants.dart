/// API constants and endpoint paths for the GiziGo backend.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (baseUrlOverride.isNotEmpty) return baseUrlOverride;
    return baseUrlProduction;
  }

  static const String baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String baseUrlProduction = 'https://be-gizigo.vercel.app';
  static const String baseUrlAndroid = 'http://10.135.63.145:3000';
  static const String baseUrlAndroidEmulator = 'http://10.0.2.2:3000';
  static const String baseUrlLocalhost = 'http://localhost:3000';

  static const String firebaseIdTokenStorageKey = 'firebase_id_token';

  static const String root = '/';
  static const String swagger = '/api';

  static const String signup = '/auth/signup';
  static const String authSync = '/auth/sync';

  static const String usersMe = '/users/me';
  static const String usersMePhoto = '/users/me/photo';
  static const String usersRecentlyViewed = '/users/me/recently-viewed';
  static const String usersRecentLocations = '/users/me/recent-locations';

  static const String foods = '/foods';
  static const String foodSearch = '/foods/search';
  static const String foodRecommendations = '/foods/recommendations';

  static const String metaFoodCategories = '/meta/food-categories';
  static const String metaNutritionGrades = '/meta/nutrition-grades';
  static const String metaNutritionGoals = '/meta/nutrition-goals';
  static const String metaLocationsSearch = '/meta/locations/search';

  static const String merchantMe = '/merchant/me';
  static const String merchantFoods = '/merchant/foods';

  static const String adminMerchants = '/admin/merchants';
  static const String adminFoods = '/admin/foods';

  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  static String foodDetails(String id) => '$foods/${Uri.encodeComponent(id)}';

  static String adminFoodDetails(String id) =>
      '$adminFoods/${Uri.encodeComponent(id)}';

  static String merchantFoodDetails(String id) =>
      '$merchantFoods/${Uri.encodeComponent(id)}';

  static String merchantFoodPhoto(String id) =>
      '${merchantFoodDetails(id)}/photo';

  static String adminMerchantDetails(String id) =>
      '$adminMerchants/${Uri.encodeComponent(id)}';

  static String adminMerchantFoods(String id) =>
      '${adminMerchantDetails(id)}/foods';

  static String adminFoodPhoto(String id) => '${adminFoodDetails(id)}/photo';
}
