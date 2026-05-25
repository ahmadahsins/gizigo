class HomeCategory {
  const HomeCategory({
    required this.key,
    required this.title,
    required this.iconAsset,
  });

  final String key;
  final String title;
  final String iconAsset;

  static const List<HomeCategory> defaultCategories = [
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

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    final key = _asString(json['key']);

    return HomeCategory(
      key: key,
      title: _asString(json['label_en'], fallback: key),
      iconAsset: _iconAssetFor(key),
    );
  }

  static String _iconAssetFor(String key) {
    return switch (key) {
      'main_course' => 'assets/icons/categories-menu/main-course.svg',
      'appetizers' => 'assets/icons/categories-menu/appetizers.svg',
      'snacks' => 'assets/icons/categories-menu/snacks.svg',
      'desserts' => 'assets/icons/categories-menu/desserts.svg',
      'beverages' => 'assets/icons/categories-menu/beverages.svg',
      'breakfast' => 'assets/icons/categories-menu/breakfast.svg',
      'lunch' => 'assets/icons/categories-menu/lunch.svg',
      'dinner' => 'assets/icons/categories-menu/dinner.svg',
      'salads' => 'assets/icons/categories-menu/salads.svg',
      _ => 'assets/icons/categories-menu/main-course.svg',
    };
  }

  static List<HomeCategory> withDefaultCategories(
    List<HomeCategory> categories,
  ) {
    if (categories.isEmpty) return defaultCategories;

    final categoriesByKey = {
      for (final category in categories)
        if (category.key.isNotEmpty) category.key: category,
    };
    final defaultKeys = defaultCategories
        .map((category) => category.key)
        .toSet();

    return [
      for (final defaultCategory in defaultCategories)
        categoriesByKey[defaultCategory.key] ?? defaultCategory,
      for (final category in categories)
        if (!defaultKeys.contains(category.key)) category,
    ];
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
