import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../home/presentation/widgets/filter_dropdown_chip.dart';
import '../../../home/presentation/widgets/recommendation_card.dart';
import '../../domain/entities/search_food_item.dart';

class SearchResultsContent extends StatelessWidget {
  const SearchResultsContent({
    super.key,
    required this.horizontalPadding,
    required this.foods,
    required this.onFilterTap,
    required this.onPriceFilterTap,
    required this.onLabelFilterTap,
    required this.onRangeFilterTap,
    required this.onFoodTap,
    this.hasAnyFilter = false,
    this.hasPriceFilter = false,
    this.hasLabelFilter = false,
    this.hasRangeFilter = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final double horizontalPadding;
  final List<SearchFoodItem> foods;
  final VoidCallback onFilterTap;
  final VoidCallback onPriceFilterTap;
  final VoidCallback onLabelFilterTap;
  final VoidCallback onRangeFilterTap;
  final ValueChanged<SearchFoodItem> onFoodTap;
  final bool hasAnyFilter;
  final bool hasPriceFilter;
  final bool hasLabelFilter;
  final bool hasRangeFilter;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 19),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              FilterDropdownChip(
                label: 'Filters',
                onTap: onFilterTap,
                isActive: hasAnyFilter,
              ),
              const SizedBox(width: 12),
              FilterDropdownChip(
                label: 'Price',
                onTap: onPriceFilterTap,
                isActive: hasPriceFilter,
              ),
              const SizedBox(width: 12),
              FilterDropdownChip(
                label: 'Label',
                onTap: onLabelFilterTap,
                isActive: hasLabelFilter,
              ),
              const SizedBox(width: 12),
              FilterDropdownChip(
                label: 'Range',
                onTap: onRangeFilterTap,
                isActive: hasRangeFilter,
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        Expanded(
          child: isLoading
              ? _SearchLoadingState(horizontalPadding: horizontalPadding)
              : errorMessage != null
              ? _SearchStatus(message: errorMessage!)
              : foods.isEmpty
              ? const _SearchStatus(message: 'No menu found')
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    34,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return _SearchResultTile(
                      food: food,
                      onTap: () => onFoodTap(food),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.food, required this.onTap});

  final SearchFoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RecommendationCard(
      imageUrl: food.imageUrl,
      title: food.title,
      subtitle: food.subtitle,
      price: food.price,
      ratingText: food.ratingText,
      onTap: onTap,
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 34),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const AppSkeletonRecommendationCard();
      },
    );
  }
}

class _SearchStatus extends StatelessWidget {
  const _SearchStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
