import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/presentation/widgets/filter_dropdown_chip.dart';
import '../../../home/presentation/widgets/rating_badge.dart';
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
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    34,
                  ),
                  itemCount: foods.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
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
    return Row(
      children: [
        _NetworkFoodImage(
          imageUrl: food.imageUrl,
          width: 91,
          height: 91,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                food.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                food.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  RatingBadge(text: food.ratingText),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      food.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.price.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetworkFoodImage extends StatelessWidget {
  const _NetworkFoodImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFE9E9E9),
            child: const Icon(
              Icons.image_not_supported_rounded,
              color: Color(0xFF9A9A9A),
              size: 28,
            ),
          );
        },
      ),
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
