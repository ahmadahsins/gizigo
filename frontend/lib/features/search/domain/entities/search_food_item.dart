class SearchFoodItem {
  const SearchFoodItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.ratingText,
    required this.distanceKm,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String price;
  final String ratingText;
  final double distanceKm;
  final String imageUrl;
}
