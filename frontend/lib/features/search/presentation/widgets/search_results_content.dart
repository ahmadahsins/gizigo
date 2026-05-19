import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    this.hasAnyFilter = false,
    this.hasPriceFilter = false,
    this.hasLabelFilter = false,
    this.hasRangeFilter = false,
  });

  final double horizontalPadding;
  final List<SearchFoodItem> foods;
  final VoidCallback onFilterTap;
  final VoidCallback onPriceFilterTap;
  final VoidCallback onLabelFilterTap;
  final VoidCallback onRangeFilterTap;
  final bool hasAnyFilter;
  final bool hasPriceFilter;
  final bool hasLabelFilter;
  final bool hasRangeFilter;

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
          child: foods.isEmpty
              ? const _EmptySearchResult()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    34,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    return _SearchResultTile(food: foods[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.food});

  final SearchFoodItem food;

  @override
  Widget build(BuildContext context) {
    return RecommendationCard(
      imageUrl: food.imageUrl,
      title: food.title,
      subtitle: food.subtitle,
      price: food.price,
      ratingText: food.ratingText,
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No menu found',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
