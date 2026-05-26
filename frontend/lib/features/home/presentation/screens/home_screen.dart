import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auto_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../router/app_router.dart';
import '../../../location/domain/entities/location_item.dart';
import '../../data/models/home_category.dart';
import '../../data/models/home_food_item.dart';
import '../providers/home_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_dropdown_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/categories_section.dart';
import '../widgets/featured_food_card.dart';
import '../widgets/recommendation_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutoRefreshStateMixin<HomeScreen> {
  LocationItem? _selectedLocation;

  HomeRequest get _homeRequest {
    final location = _selectedLocation;

    return HomeRequest(lat: location?.latitude, lng: location?.longitude);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialLocation);
  }

  @override
  Future<void> onAutoRefresh() {
    return _refreshHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final request = _homeRequest;
    final fallbackCategories = ref.watch(homeCategoriesProvider);
    final userProfile =
        ref.watch(homeUserProfileProvider).valueOrNull ??
        const HomeUserProfile(displayName: 'there', profilePhotoUrl: '');
    final homeAsync = ref.watch(homeDataProvider(request));
    final homeData = homeAsync.valueOrNull;
    final categories = homeData?.categories ?? fallbackCategories;
    final isInitialLoading = homeAsync.isLoading && homeData == null;
    final recommendationsError = homeData?.recommendationsError;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshHomeData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: HomeHeader(
                    userName: userProfile.displayName,
                    profilePhotoUrl: userProfile.profilePhotoUrl,
                    locationName: _selectedLocation?.name,
                    onLocationTap: _openLocationSelection,
                    onProfileTap: _openProfile,
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomSearchBar(
                    onTap: () => context.pushNamed(AppRouter.search),
                  ),
                ),
                const SizedBox(height: 20),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      FilterDropdownChip(
                        label: 'Filters',
                        onTap: _openSearchFilters,
                      ),
                      const SizedBox(width: 8),
                      FilterDropdownChip(
                        label: 'Price',
                        onTap: _openSearchFilters,
                      ),
                      const SizedBox(width: 8),
                      FilterDropdownChip(
                        label: 'Label',
                        onTap: _openSearchFilters,
                      ),
                      const SizedBox(width: 8),
                      FilterDropdownChip(
                        label: 'Range',
                        onTap: _openSearchFilters,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                CategoriesSection(
                  categories: categories,
                  isLoading: isInitialLoading,
                  onCategoryTap: _openCategorySearch,
                ),
                const SizedBox(height: 32),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(title: 'You Might Like This'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildFeaturedSection(
                    featured: homeData?.featured ?? const [],
                    isLoading: isInitialLoading,
                    error: recommendationsError,
                  ),
                ),
                const SizedBox(height: 32),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(title: 'Recommendations for You'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildRecommendationsSection(
                    foods: homeData?.recommendations ?? const [],
                    isLoading: isInitialLoading,
                    error: recommendationsError,
                  ),
                ),
              ],
            ),
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

    await ref
        .read(locationStorageServiceProvider)
        .saveSelectedLocation(selectedLocation);

    setState(() {
      _selectedLocation = selectedLocation;
    });
    AutoRefreshService.instance.refreshNow();
  }

  Future<void> _openProfile() async {
    await context.pushNamed(AppRouter.profile);
    if (!mounted) return;

    await _refreshHomeData();
  }

  void _openSearchFilters() {
    context.pushNamed(
      AppRouter.search,
      queryParameters: const {'open_filter': '1'},
    );
  }

  void _openCategorySearch(HomeCategory category) {
    context.pushNamed(
      AppRouter.search,
      queryParameters: {
        'category': category.key,
        'category_title': category.title,
      },
    );
  }

  Future<void> _loadInitialLocation() async {
    final location = await ref.read(selectedLocationProvider.future);
    if (!mounted || location == null) return;

    setState(() => _selectedLocation = location);
  }

  Future<void> _refreshHomeData() async {
    final previousRequest = _homeRequest;

    ref.invalidate(homeUserProfileProvider);
    ref.invalidate(selectedLocationProvider);
    ref.invalidate(homeDataProvider(previousRequest));

    try {
      final location = await ref.read(selectedLocationProvider.future);
      if (mounted) {
        setState(() => _selectedLocation = location);
      }
    } catch (_) {}

    if (!mounted) return;

    final nextRequest = _homeRequest;
    ref.invalidate(homeDataProvider(nextRequest));
    await ref.read(homeDataProvider(nextRequest).future);
  }

  Widget _buildFeaturedSection({
    required List<HomeFoodItem> featured,
    required bool isLoading,
    required Object? error,
  }) {
    if (isLoading) return const _HomeLoadingCard(height: 292);

    if (error != null) {
      return _HomeEmptyState(message: _errorMessage(error));
    }

    final food = featured.firstOrNull;
    if (food == null) {
      return const _HomeEmptyState(message: 'No featured food available yet.');
    }

    return FeaturedFoodCard(
      imageUrl: food.imageUrl,
      title: food.name,
      merchant: food.vendorName.isEmpty ? food.description : food.vendorName,
      price: food.formattedPrice,
      ratingText: food.ratingText,
      onViewFullMenuTap: () => _openFoodDetail(food),
    );
  }

  Widget _buildRecommendationsSection({
    required List<HomeFoodItem> foods,
    required bool isLoading,
    required Object? error,
  }) {
    if (isLoading) {
      return const Column(
        children: [
          AppSkeletonRecommendationCard(),
          AppSkeletonRecommendationCard(),
          AppSkeletonRecommendationCard(),
        ],
      );
    }

    if (error != null) {
      return _HomeEmptyState(message: _errorMessage(error));
    }

    if (foods.isEmpty) {
      return const _HomeEmptyState(
        message: 'No recommendations available yet.',
      );
    }

    return Column(
      children: foods.map((food) {
        return RecommendationCard(
          imageUrl: food.imageUrl,
          title: food.name,
          subtitle: food.subtitle,
          price: food.formattedPrice,
          ratingText: food.ratingText,
          onTap: () => _openFoodDetail(food),
        );
      }).toList(),
    );
  }

  void _openFoodDetail(HomeFoodItem food) {
    if (food.id.isEmpty) return;

    context.pushNamed(AppRouter.foodDetail, pathParameters: {'id': food.id});
  }

  String _errorMessage(Object? error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Session kamu belum valid. Silakan login ulang, lalu tarik layar untuk refresh.';
    }

    return 'Home data belum bisa dimuat. Cek koneksi atau backend, lalu coba lagi.';
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: AppSkeletonBox(
        height: height,
        width: double.infinity,
        borderRadius: 8,
      ),
    );
  }
}
