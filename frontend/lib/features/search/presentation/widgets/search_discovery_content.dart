import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/models/home_category.dart';
import '../../../home/presentation/widgets/featured_food_card.dart';
import '../../domain/entities/search_food_item.dart';
import 'search_section_title.dart';

class SearchDiscoveryContent extends StatelessWidget {
  const SearchDiscoveryContent({
    super.key,
    required this.horizontalPadding,
    required this.history,
    required this.categories,
    required this.onHistoryTap,
    required this.onCategoryTap,
    this.featuredFood,
    this.onFeaturedTap,
    this.isLoadingFeatured = false,
  });

  final double horizontalPadding;
  final List<String> history;
  final List<HomeCategory> categories;
  final SearchFoodItem? featuredFood;
  final ValueChanged<String> onHistoryTap;
  final ValueChanged<HomeCategory> onCategoryTap;
  final VoidCallback? onFeaturedTap;
  final bool isLoadingFeatured;

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
          if (isLoadingFeatured)
            const _FeaturedLoadingCard()
          else if (featuredFood != null)
            FeaturedFoodCard(
              imageUrl: featuredFood!.imageUrl,
              title: featuredFood!.title,
              merchant: featuredFood!.subtitle,
              price: featuredFood!.price,
              ratingText: featuredFood!.ratingText,
              onViewFullMenuTap: onFeaturedTap,
            )
          else
            const _FeaturedEmptyState(),
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

  final List<HomeCategory> categories;
  final ValueChanged<HomeCategory> onTap;

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
                onTap: () => onTap(category),
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

  final HomeCategory category;
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
            child: SvgPicture.asset(category.iconAsset, fit: BoxFit.contain),
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

class _FeaturedLoadingCard extends StatelessWidget {
  const _FeaturedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 292,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeaturedEmptyState extends StatelessWidget {
  const _FeaturedEmptyState();

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
        'No featured food available yet.',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
