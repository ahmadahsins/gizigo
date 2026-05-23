class HomeCategory {
  const HomeCategory({
    required this.key,
    required this.title,
    required this.iconAsset,
  });

  final String key;
  final String title;
  final String iconAsset;

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
      _ => 'assets/icons/categories-menu/main-course.svg',
    };
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
