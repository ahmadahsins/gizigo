import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/search_mock_data.dart';
import '../../domain/entities/search_food_item.dart';
import '../widgets/label_filter_bottom_sheet.dart';
import '../widgets/price_filter_bottom_sheet.dart';
import '../widgets/range_filter_bottom_sheet.dart';
import '../widgets/search_discovery_content.dart';
import '../widgets/search_filters_bottom_sheet.dart';
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
  final Set<String> _selectedLabels = {};
  final Set<String> _selectedRanges = {};
  RangeValues _selectedPriceRange = PriceFilterBottomSheet.defaultRange;

  String _query = '';

  List<SearchFoodItem> get _filteredFoods {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    var matches = searchFoods.where((food) {
      return food.title.toLowerCase().contains(normalizedQuery) ||
          food.subtitle.toLowerCase().contains(normalizedQuery);
    });

    if (_selectedLabels.isNotEmpty) {
      matches = matches.where((food) {
        return _selectedLabels.contains(food.ratingText);
      });
    }

    if (_hasPriceFilter) {
      matches = matches.where((food) {
        final price = _parseRupiah(food.price);
        return price >= _selectedPriceRange.start &&
            price <= _selectedPriceRange.end;
      });
    }

    if (_selectedRanges.isNotEmpty) {
      matches = matches.where((food) {
        return _selectedRanges.any((range) {
          return _matchesDistanceRange(food.distanceKm, range);
        });
      });
    }

    return matches.toList();
  }

  List<String> get _latestSearchHistory => _searchHistory.take(4).toList();

  bool get _hasPriceFilter {
    return _selectedPriceRange.start != PriceFilterBottomSheet.minPrice ||
        _selectedPriceRange.end != PriceFilterBottomSheet.maxPrice;
  }

  bool get _hasAnyFilter {
    return _hasPriceFilter ||
        _selectedLabels.isNotEmpty ||
        _selectedRanges.isNotEmpty;
  }

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
                              onPriceFilterTap: _handlePriceFilterTap,
                              onLabelFilterTap: _handleLabelFilterTap,
                              onRangeFilterTap: _handleRangeFilterTap,
                              hasAnyFilter: _hasAnyFilter,
                              hasPriceFilter: _hasPriceFilter,
                              hasLabelFilter: _selectedLabels.isNotEmpty,
                              hasRangeFilter: _selectedRanges.isNotEmpty,
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

  Future<void> _handleFilterTap() async {
    _unfocusSearch();

    final selectedFilters = await showModalBottomSheet<SearchFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) {
        return SearchFiltersBottomSheet(
          initialSelection: SearchFilterSelection(
            priceRange: _selectedPriceRange,
            selectedLabels: _selectedLabels,
            selectedRanges: _selectedRanges,
          ),
        );
      },
    );

    if (!mounted || selectedFilters == null) return;

    setState(() {
      _selectedPriceRange = selectedFilters.priceRange;
      _selectedLabels
        ..clear()
        ..addAll(selectedFilters.selectedLabels);
      _selectedRanges
        ..clear()
        ..addAll(selectedFilters.selectedRanges);
    });
  }

  Future<void> _handlePriceFilterTap() async {
    _unfocusSearch();

    final selectedRange = await showModalBottomSheet<RangeValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) {
        return PriceFilterBottomSheet(initialRange: _selectedPriceRange);
      },
    );

    if (!mounted || selectedRange == null) return;

    setState(() => _selectedPriceRange = selectedRange);
  }

  Future<void> _handleLabelFilterTap() async {
    _unfocusSearch();

    final selectedLabels = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) {
        return LabelFilterBottomSheet(initialSelectedLabels: _selectedLabels);
      },
    );

    if (!mounted || selectedLabels == null) return;

    setState(() {
      _selectedLabels
        ..clear()
        ..addAll(selectedLabels);
    });
  }

  Future<void> _handleRangeFilterTap() async {
    _unfocusSearch();

    final selectedRanges = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) {
        return RangeFilterBottomSheet(initialSelectedRanges: _selectedRanges);
      },
    );

    if (!mounted || selectedRanges == null) return;

    setState(() {
      _selectedRanges
        ..clear()
        ..addAll(selectedRanges);
    });
  }

  void _unfocusSearch() {
    FocusScope.of(context).unfocus();
  }

  double _parseRupiah(String value) {
    final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(numericValue) ?? 0;
  }

  bool _matchesDistanceRange(double distanceKm, String range) {
    return switch (range) {
      RangeFilterBottomSheet.lessThanTwoKm => distanceKm < 2,
      RangeFilterBottomSheet.twoToFiveKm => distanceKm >= 2 && distanceKm <= 5,
      RangeFilterBottomSheet.moreThanFiveKm => distanceKm > 5,
      _ => false,
    };
  }
}
