/// App-wide constants for GiziGo
class AppConstants {
  AppConstants._();

  static const String appName = 'GiziGo';
  static const String appTagline = 'Makan Sehat, Harga Bersahabat';

  // Health Labels
  static const List<String> healthLabels = [
    'High Protein',
    'Low Calorie',
    'Vegan',
    'Vegetarian',
    'Low Carb',
    'Gluten Free',
    'Dairy Free',
    'Sugar Free',
  ];

  // Food Delivery Services
  static const String goFood = 'GoFood';
  static const String grabFood = 'GrabFood';
  static const String shopeeFood = 'ShopeeFood';

  // Search radius in km
  static const double defaultSearchRadius = 5.0;
  static const double maxSearchRadius = 10.0;
}
