import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/app_router.dart';
import '../../../location/domain/entities/location_item.dart';
import '../widgets/home_header.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_dropdown_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/categories_section.dart';
import '../widgets/featured_food_card.dart';
import '../widgets/recommendation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _locationName = 'UGM, Yogyakarta';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Location Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: HomeHeader(
                  locationName: _locationName,
                  onLocationTap: _openLocationSelection,
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomSearchBar(
                  onTap: () => context.pushNamed(AppRouter.search),
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: const [
                    FilterDropdownChip(label: 'Filters'),
                    SizedBox(width: 8),
                    FilterDropdownChip(label: 'Price'),
                    SizedBox(width: 8),
                    FilterDropdownChip(label: 'Label'),
                    SizedBox(width: 8),
                    FilterDropdownChip(label: 'Range'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Categories Section
              const CategoriesSection(),
              const SizedBox(height: 32),

              // Featured Food Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(title: 'You Might Like This'),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FeaturedFoodCard(
                  imageUrl: '',
                  title: 'Ayam goreng',
                  merchant: 'Warteg Sendowo',
                  price: 'Rp17.000',
                  ratingText: 'Excellent',
                  onViewFullMenuTap: () {},
                ),
              ),
              const SizedBox(height: 32),

              // Recommendations Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(title: 'Recommendations for You'),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    RecommendationCard(
                      imageUrl: '',
                      title: 'Lorem ipsum',
                      subtitle: 'Lorem ipsum',
                      price: 'Rp16.000',
                      ratingText: 'Excellent',
                    ),
                    RecommendationCard(
                      imageUrl: '',
                      title: 'Lorem ipsum',
                      subtitle: 'Lorem ipsum',
                      price: 'Rp14.000',
                      ratingText: 'Very good',
                    ),
                    RecommendationCard(
                      imageUrl: '',
                      title: 'Lorem ipsum',
                      subtitle: 'Lorem ipsum',
                      price: 'Rp15.500',
                      ratingText: 'Excellent',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationSelection() async {
    final selectedLocation = await context.pushNamed<LocationItem>(
      AppRouter.selectLocation,
    );
    if (!mounted || selectedLocation == null) return;

    setState(() => _locationName = selectedLocation.name);
  }
}
