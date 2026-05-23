import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/nutrition_grade.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../router/app_router.dart';
import '../../../home/data/models/home_category.dart';
import '../../../location/data/location_storage_service.dart';
import '../../../location/domain/entities/location_item.dart';
import '../../data/search_remote_data_source.dart';
import '../../domain/entities/search_food_item.dart';
import '../widgets/label_filter_bottom_sheet.dart';
import '../widgets/price_filter_bottom_sheet.dart';
import '../widgets/range_filter_bottom_sheet.dart';
import '../widgets/search_discovery_content.dart';
import '../widgets/search_filters_bottom_sheet.dart';
import '../widgets/search_header.dart';
import '../widgets/search_results_content.dart';

/// Search Screen - Search food by name, category, nutrition label, price, and range.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryKey,
    this.initialCategoryTitle,
    this.openFilterOnStart = false,
  });

  final String? initialQuery;
  final String? initialCategoryKey;
  final String? initialCategoryTitle;
  final bool openFilterOnStart;

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
  final LocationStorageService _locationStorage =
      const LocationStorageService();
  late final SearchRemoteDataSource _searchRemoteDataSource;

  RangeValues _selectedPriceRange = PriceFilterBottomSheet.defaultRange;
  Timer? _searchDebounce;
  String _query = '';
  String? _selectedCategoryKey;
  LocationItem? _selectedLocation;
  List<HomeCategory> _categories = const [];
  SearchFoodItem? _featuredFood;
  List<SearchFoodItem> _foods = const [];
  Object? _searchError;
  bool _isLoadingSearch = false;
  bool _isLoadingDiscovery = true;
  int _searchGeneration = 0;

  List<String> get _latestSearchHistory => _searchHistory.take(4).toList();

  bool get _hasPriceFilter {
    return _selectedPriceRange.start != PriceFilterBottomSheet.minPrice ||
        _selectedPriceRange.end != PriceFilterBottomSheet.maxPrice;
  }

  bool get _hasAnyFilter {
    return _hasPriceFilter ||
        _selectedLabels.isNotEmpty ||
        _selectedRanges.isNotEmpty ||
        _selectedCategoryKey != null;
  }

  bool get _hasSearchRequest {
    return _query.trim().isNotEmpty || _hasAnyFilter;
  }

  @override
  void initState() {
    super.initState();
    _searchRemoteDataSource = SearchRemoteDataSource(DioClient());
    _selectedCategoryKey = _cleanText(widget.initialCategoryKey);
    final initialQuery = _cleanText(widget.initialQuery);
    if (initialQuery != null) {
      _searchController.text = initialQuery;
      _query = initialQuery;
    }
    _searchController.addListener(_handleSearchChanged);
    Future.microtask(_loadInitialData);

    if (widget.openFilterOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleFilterTap();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
                      child: _hasSearchRequest
                          ? SearchResultsContent(
                              horizontalPadding: horizontalPadding,
                              foods: _foods,
                              onFilterTap: _handleFilterTap,
                              onPriceFilterTap: _handlePriceFilterTap,
                              onLabelFilterTap: _handleLabelFilterTap,
                              onRangeFilterTap: _handleRangeFilterTap,
                              onFoodTap: _openFoodDetail,
                              hasAnyFilter: _hasAnyFilter,
                              hasPriceFilter: _hasPriceFilter,
                              hasLabelFilter: _selectedLabels.isNotEmpty,
                              hasRangeFilter: _selectedRanges.isNotEmpty,
                              isLoading: _isLoadingSearch,
                              errorMessage: _searchErrorMessage(_searchError),
                            )
                          : SearchDiscoveryContent(
                              horizontalPadding: horizontalPadding,
                              history: _latestSearchHistory,
                              categories: _categories,
                              featuredFood: _featuredFood,
                              isLoadingFeatured: _isLoadingDiscovery,
                              onHistoryTap: _selectSearchText,
                              onCategoryTap: _selectCategory,
                              onFeaturedTap: _featuredFood == null
                                  ? null
                                  : () => _openFoodDetail(_featuredFood!),
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

  Future<void> _loadInitialData() async {
    _selectedLocation = await _locationStorage.readSelectedLocation();

    await Future.wait([_loadCategories(), _loadFeaturedFood()]);

    if (_hasSearchRequest) {
      _runSearch(showLoading: true);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _searchRemoteDataSource.getCategories();
      if (!mounted) return;

      setState(() => _categories = categories);
    } catch (_) {
      if (!mounted) return;
      setState(() => _categories = const []);
    }
  }

  Future<void> _loadFeaturedFood() async {
    setState(() => _isLoadingDiscovery = true);

    try {
      final location = _selectedLocation;
      final featured = await _searchRemoteDataSource.getFeaturedFood(
        lat: location?.latitude,
        lng: location?.longitude,
      );
      if (!mounted) return;

      setState(() {
        _featuredFood = featured;
        _isLoadingDiscovery = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDiscovery = false);
    }
  }

  void _handleSearchChanged() {
    final value = _searchController.text;
    if (value == _query) return;

    setState(() {
      _query = value;
      _selectedCategoryKey = null;
    });

    _scheduleSearch();
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    if (!_hasSearchRequest) {
      _searchGeneration++;
      setState(() {
        _foods = const [];
        _searchError = null;
        _isLoadingSearch = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _runSearch(showLoading: true);
    });
  }

  Future<void> _runSearch({required bool showLoading}) async {
    final generation = ++_searchGeneration;
    if (showLoading) {
      setState(() {
        _isLoadingSearch = true;
        _searchError = null;
      });
    }

    try {
      final response = await _searchRemoteDataSource.searchFoods(
        query: _query,
        categoryKey: _selectedCategoryKey,
        nutritionGrade: _selectedNutritionGradeQuery,
        minPrice: _hasPriceFilter ? _selectedPriceRange.start : null,
        maxPrice: _hasPriceFilter ? _selectedPriceRange.end : null,
        lat: _selectedLocation?.latitude,
        lng: _selectedLocation?.longitude,
        maxDistanceKm: _maxDistanceQuery,
      );

      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        _foods = _applyDistanceFilters(response.items);
        _searchError = null;
        _isLoadingSearch = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        _foods = const [];
        _searchError = error;
        _isLoadingSearch = false;
      });
    }
  }

  String? get _selectedNutritionGradeQuery {
    if (_selectedLabels.length != 1) return null;

    final grade = NutritionGrade.tryParse(_selectedLabels.first);
    return switch (grade) {
      NutritionGrade.good => 'GOOD',
      NutritionGrade.veryGood => 'VERY_GOOD',
      NutritionGrade.excellent => 'EXCELLENT',
      null => null,
    };
  }

  double? get _maxDistanceQuery {
    if (_selectedLocation == null || _selectedRanges.isEmpty) return null;
    if (_selectedRanges.contains(RangeFilterBottomSheet.moreThanFiveKm)) {
      return null;
    }
    if (_selectedRanges.contains(RangeFilterBottomSheet.twoToFiveKm)) {
      return 5;
    }
    if (_selectedRanges.contains(RangeFilterBottomSheet.lessThanTwoKm)) {
      return 2;
    }
    return null;
  }

  List<SearchFoodItem> _applyDistanceFilters(List<SearchFoodItem> items) {
    var results = items;

    if (_selectedLabels.length > 1) {
      results = results
          .where((food) {
            return _selectedLabels.contains(food.ratingText);
          })
          .toList(growable: false);
    }

    if (_selectedRanges.isEmpty) return results;

    return results
        .where((food) {
          final distance = food.distanceKm;
          if (distance == null) return false;

          return _selectedRanges.any(
            (range) => _matchesDistanceRange(distance, range),
          );
        })
        .toList(growable: false);
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
    _runSearch(showLoading: true);
  }

  void _selectSearchText(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _unfocusSearch();
    _submitSearch(value);
  }

  void _selectCategory(HomeCategory category) {
    _unfocusSearch();
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategoryKey = category.key;
    });
    _runSearch(showLoading: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategoryKey = null;
    });
    _searchFocusNode.requestFocus();
    _scheduleSearch();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed(AppRouter.home);
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
    _runSearch(showLoading: true);
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
    _runSearch(showLoading: true);
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
    _runSearch(showLoading: true);
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
    _runSearch(showLoading: true);
  }

  void _openFoodDetail(SearchFoodItem food) {
    if (food.id.isEmpty) return;

    context.pushNamed(AppRouter.foodDetail, pathParameters: {'id': food.id});
  }

  void _unfocusSearch() {
    FocusScope.of(context).unfocus();
  }

  bool _matchesDistanceRange(double distanceKm, String range) {
    return switch (range) {
      RangeFilterBottomSheet.lessThanTwoKm => distanceKm < 2,
      RangeFilterBottomSheet.twoToFiveKm => distanceKm >= 2 && distanceKm <= 5,
      RangeFilterBottomSheet.moreThanFiveKm => distanceKm > 5,
      _ => false,
    };
  }

  String? _searchErrorMessage(Object? error) {
    if (error == null) return null;
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Session kamu belum valid. Silakan login ulang.';
    }

    return 'Search belum bisa dimuat. Cek koneksi atau backend, lalu coba lagi.';
  }

  String? _cleanText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
