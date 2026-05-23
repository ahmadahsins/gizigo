import 'package:flutter/material.dart';

import '../../data/models/home_category.dart';
import 'section_header.dart';
import 'category_item_card.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({
    super.key,
    required this.categories,
    this.isLoading = false,
    this.onCategoryTap,
  });

  final List<HomeCategory> categories;
  final bool isLoading;
  final ValueChanged<HomeCategory>? onCategoryTap;

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.categories.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Categories',
            actionText: canExpand
                ? (_isExpanded ? 'Show less' : 'View all')
                : null,
            onActionTap: canExpand
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isLoading)
          const _CategoryLoadingRow()
        else if (widget.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _CategoryEmptyState(),
          )
        else if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 3;
                return Wrap(
                  runSpacing: 16,
                  children: widget.categories.map((category) {
                    return SizedBox(
                      width: itemWidth,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: CategoryItemCard(
                          title: category.title,
                          imageUrl: category.iconAsset,
                          onTap: () => widget.onCategoryTap?.call(category),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CategoryItemCard(
                    title: category.title,
                    imageUrl: category.iconAsset,
                    onTap: () => widget.onCategoryTap?.call(category),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _CategoryLoadingRow extends StatelessWidget {
  const _CategoryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(
          5,
          (index) => Container(
            width: 76,
            height: 104,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: const Text('No categories available yet.'),
    );
  }
}
