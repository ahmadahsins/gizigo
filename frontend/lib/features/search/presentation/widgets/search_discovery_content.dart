import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../home/presentation/widgets/rating_badge.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_food_item.dart';
import 'search_section_title.dart';

class SearchDiscoveryContent extends StatelessWidget {
  const SearchDiscoveryContent({
    super.key,
    required this.horizontalPadding,
    required this.history,
    required this.categories,
    required this.featuredFood,
    required this.onHistoryTap,
    required this.onCategoryTap,
  });

  final double horizontalPadding;
  final List<String> history;
  final List<SearchCategory> categories;
  final SearchFoodItem featuredFood;
  final ValueChanged<String> onHistoryTap;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        31,
        horizontalPadding,
        34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            const SearchSectionTitle('Search history'),
            const SizedBox(height: 18),
            _SearchHistoryWrap(history: history, onTap: onHistoryTap),
            const SizedBox(height: 35),
          ],
          const SearchSectionTitle('Categories'),
          const SizedBox(height: 16),
          _CategoriesGrid(categories: categories, onTap: onCategoryTap),
          const SizedBox(height: 43),
          const SearchSectionTitle('You Might Like This'),
          const SizedBox(height: 17),
          _FeaturedSearchCard(food: featuredFood),
        ],
      ),
    );
  }
}

class _SearchHistoryWrap extends StatelessWidget {
  const _SearchHistoryWrap({required this.history, required this.onTap});

  final List<String> history;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 15,
      runSpacing: 13,
      children: history.map((item) {
        return _HistoryChip(label: item, onTap: () => onTap(item));
      }).toList(),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(24),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: Color(0xFF5D5D5D),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF464646),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories, required this.onTap});

  final List<SearchCategory> categories;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 3;

        return Wrap(
          runSpacing: 29,
          children: categories.map((category) {
            return SizedBox(
              width: itemWidth,
              child: _CategoryCard(
                category: category,
                onTap: () => onTap(category.title),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final SearchCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE8E3E3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SvgPicture.asset(category.iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 7),
          Text(
            category.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: const Color(0xFF2B2B2B),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSearchCard extends StatelessWidget {
  const _FeaturedSearchCard({required this.food});

  final SearchFoodItem food;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  food.imageUrl,
                  height: 217,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ImageFallback(height: 217);
                  },
                ),
              ),
              Positioned(
                top: 17,
                right: 15,
                child: RatingBadge(text: food.ratingText),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            food.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF202124),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      food.price,
                      style: AppTextStyles.price.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                PrimaryButton(text: 'View Full Menu', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE9E9E9),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: Color(0xFF9A9A9A),
        size: 28,
      ),
    );
  }
}
