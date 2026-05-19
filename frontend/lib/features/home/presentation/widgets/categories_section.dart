import 'package:flutter/material.dart';
import 'section_header.dart';
import 'category_item_card.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  bool _isExpanded = false;

  final List<Map<String, String>> _categories = [
    {'title': 'Main Course', 'icon': 'assets/icons/categories-menu/main-course.svg'},
    {'title': 'Appetizers', 'icon': 'assets/icons/categories-menu/appetizers.svg'},
    {'title': 'Snacks', 'icon': 'assets/icons/categories-menu/snacks.svg'},
    {'title': 'Desserts', 'icon': 'assets/icons/categories-menu/desserts.svg'},
    {'title': 'Beverages', 'icon': 'assets/icons/categories-menu/beverages.svg'},
    {'title': 'Breakfast', 'icon': 'assets/icons/categories-menu/breakfast.svg'},
    {'title': 'Lunch', 'icon': 'assets/icons/categories-menu/lunch.svg'},
    {'title': 'Dinner', 'icon': 'assets/icons/categories-menu/dinner.svg'},
    {'title': 'Salads', 'icon': 'assets/icons/categories-menu/salads.svg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Categories',
            actionText: _isExpanded ? 'Show less' : 'View all',
            onActionTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 3;
                return Wrap(
                  runSpacing: 16,
                  children: _categories.map((cat) {
                    return SizedBox(
                      width: itemWidth,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: CategoryItemCard(
                          title: cat['title']!,
                          imageUrl: cat['icon']!,
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
              children: _categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CategoryItemCard(
                    title: cat['title']!,
                    imageUrl: cat['icon']!,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
