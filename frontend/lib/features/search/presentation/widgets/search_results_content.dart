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
  });

  final double horizontalPadding;
  final List<SearchFoodItem> foods;
  final VoidCallback onFilterTap;

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
              FilterDropdownChip(label: 'Filters', onTap: onFilterTap),
              const SizedBox(width: 12),
              FilterDropdownChip(label: 'Price', onTap: onFilterTap),
              const SizedBox(width: 12),
              FilterDropdownChip(label: 'Label', onTap: onFilterTap),
              const SizedBox(width: 12),
              FilterDropdownChip(label: 'Range', onTap: onFilterTap),
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
