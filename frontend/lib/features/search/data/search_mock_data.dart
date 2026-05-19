import '../domain/entities/search_category.dart';
import '../domain/entities/search_food_item.dart';

const String searchFoodImageUrl =
    'https://images.unsplash.com/photo-1627662168223-7df99068099a?auto=format&fit=crop&w=800&q=80';

const List<SearchCategory> searchCategories = [
  SearchCategory(
    title: 'Main Course',
    iconPath: 'assets/icons/categories-menu/main-course.svg',
  ),
  SearchCategory(
    title: 'Appetizers',
    iconPath: 'assets/icons/categories-menu/appetizers.svg',
  ),
  SearchCategory(
    title: 'Snacks',
    iconPath: 'assets/icons/categories-menu/snacks.svg',
  ),
  SearchCategory(
    title: 'Desserts',
    iconPath: 'assets/icons/categories-menu/desserts.svg',
  ),
  SearchCategory(
    title: 'Beverages',
    iconPath: 'assets/icons/categories-menu/beverages.svg',
  ),
  SearchCategory(
    title: 'Breakfast',
    iconPath: 'assets/icons/categories-menu/breakfast.svg',
  ),
  SearchCategory(
    title: 'Lunch',
    iconPath: 'assets/icons/categories-menu/lunch.svg',
  ),
  SearchCategory(
    title: 'Dinner',
    iconPath: 'assets/icons/categories-menu/dinner.svg',
  ),
  SearchCategory(
    title: 'Salads',
    iconPath: 'assets/icons/categories-menu/salads.svg',
  ),
];

const SearchFoodItem featuredSearchFood = SearchFoodItem(
  title: 'Ayam goreng',
  subtitle: 'Warteg Sendowo',
  price: 'Rp17.000',
  ratingText: 'Excellent',
  imageUrl: searchFoodImageUrl,
);

const List<SearchFoodItem> searchFoods = [
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp16.000',
    ratingText: 'Excellent',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp14.000',
    ratingText: 'Very good',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp15.500',
    ratingText: 'Excellent',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp16.000',
    ratingText: 'Good',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp14.000',
    ratingText: 'Very good',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp15.500',
    ratingText: 'Excellent',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp14.000',
    ratingText: 'Good',
    imageUrl: searchFoodImageUrl,
  ),
  SearchFoodItem(
    title: 'Lorem ipsum',
    subtitle: 'Ayam goreng',
    price: 'Rp16.000',
    ratingText: 'Very good',
    imageUrl: searchFoodImageUrl,
  ),
];
