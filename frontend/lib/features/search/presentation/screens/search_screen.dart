import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/search_mock_data.dart';
import '../../domain/entities/search_food_item.dart';
import '../widgets/search_discovery_content.dart';
import '../widgets/search_header.dart';
import '../widgets/search_results_content.dart';

/// Search Screen - Search food by name/description.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double horizontalPadding = 24;
  static const Color backgroundColor = Color(0xFFFAF7F7);
  static const Color searchFieldColor = Color(0xFFE2E2E2);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _searchHistory = [];

  String _query = '';

  List<SearchFoodItem> get _filteredFoods {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    return searchFoods.where((food) {
      return food.title.toLowerCase().contains(normalizedQuery) ||
          food.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<String> get _latestSearchHistory => _searchHistory.take(4).toList();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      12,
                    ),
                    child: SearchHeader(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      searchFieldColor: searchFieldColor,
                      hasQuery: hasQuery,
                      onBack: _handleBack,
                      onClear: _clearSearch,
                      onSubmitted: _submitSearch,
                      onTapOutside: _unfocusSearch,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _unfocusSearch,
                      child: hasQuery
                          ? SearchResultsContent(
                              horizontalPadding: horizontalPadding,
                              foods: _filteredFoods,
                              onFilterTap: _handleFilterTap,
                            )
                          : SearchDiscoveryContent(
                              horizontalPadding: horizontalPadding,
                              history: _latestSearchHistory,
                              categories: searchCategories,
                              featuredFood: featuredSearchFood,
                              onHistoryTap: _selectSearchText,
                              onCategoryTap: _selectSearchText,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSearchChanged() {
    setState(() => _query = _searchController.text);
  }

  void _submitSearch(String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) return;

    setState(() {
      _searchHistory.removeWhere(
        (history) => history.toLowerCase() == normalizedValue.toLowerCase(),
      );
      _searchHistory.insert(0, normalizedValue);
    });
  }

  void _selectSearchText(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _unfocusSearch();
    _submitSearch(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed('home');
  }

  void _handleFilterTap() {
    _unfocusSearch();
  }

  void _unfocusSearch() {
    FocusScope.of(context).unfocus();
  }
}
