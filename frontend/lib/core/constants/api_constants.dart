/// API Constants for GiziGo application
class ApiConstants {
  ApiConstants._();

  // Base URL - change this to your NestJS backend URL
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator localhost
  static const String baseUrlIos = 'http://localhost:3000'; // iOS simulator

  // Auth endpoints
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';

  // Food endpoints
  static const String foods = '/foods';
  static const String foodSearch = '/foods/search';

  // Price comparison
  static const String comparePrice = '/compare-price';

  // Admin endpoints
  static const String adminFoods = '/admin/foods';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
