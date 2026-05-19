import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/location_reverse_geocoding_service.dart';
import '../../domain/entities/location_item.dart';
import '../widgets/location_map_view.dart';
import '../widgets/location_search_field.dart';

class SelectLocationMapScreen extends StatefulWidget {
  const SelectLocationMapScreen({super.key});

  @override
  State<SelectLocationMapScreen> createState() =>
      _SelectLocationMapScreenState();
}

class _SelectLocationMapScreenState extends State<SelectLocationMapScreen> {
  static const LocationMapPlace _defaultPlace = LocationMapPlace(
    location: LocationItem(
      name: 'TILC Building - Main Lobby',
      address:
          'Jl. Blimbingsari No.37, Blimbing Sari, Caturtunggal, Depok, Sleman, DI Yogyakarta 55281',
      distanceLabel: '0.4km',
      latitude: -7.76892,
      longitude: 110.37972,
    ),
    type: LocationMapPlaceType.selected,
  );

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MapController _mapController = MapController();
  final LocationReverseGeocodingService _reverseGeocodingService =
      LocationReverseGeocodingService();

  LocationMapPlace _selectedPlace = _defaultPlace;
  CancelToken? _reverseGeocodingCancelToken;
  CancelToken? _searchCancelToken;
  Timer? _searchDebounce;
  List<ForwardGeocodedLocation> _searchSuggestions = const [];
  String? _searchMessage;
  int _reverseGeocodingRequestId = 0;
  int _searchRequestId = 0;
  bool _isResolvingAddress = false;
  bool _isSearchingLocations = false;
  bool _showSearchSuggestions = false;
  bool _canApplyInitialCurrentLocation = true;

  bool get _hasSearchText => _searchController.text.trim().isNotEmpty;
  bool get _shouldShowSearchSuggestions {
    return _showSearchSuggestions &&
        (_isSearchingLocations ||
            _searchSuggestions.isNotEmpty ||
            _searchMessage != null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Location map screen disposed.');
    _reverseGeocodingCancelToken?.cancel('Location map screen disposed.');
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissSearchOverlay,
        child: Stack(
          children: [
            Positioned.fill(
              child: LocationMapView(
                mapController: _mapController,
                selectedPlace: _selectedPlace,
                onMapIdle: _handleMapIdle,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 34, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocationSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _updateQuery,
                      hasText: _hasSearchText,
                      onClear: _clearSearch,
                      onSubmitted: _submitSearch,
                      onTapOutside: _unfocusSearch,
                    ),
                    if (_shouldShowSearchSuggestions) ...[
                      const SizedBox(height: 8),
                      _LocationSearchSuggestions(
                        isLoading: _isSearchingLocations,
                        message: _searchMessage,
                        suggestions: _searchSuggestions,
                        onSuggestionTap: _selectSearchSuggestion,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _LocationSelectionSheet(
                location: _selectedPlace.location,
                isResolvingAddress: _isResolvingAddress,
                onSelect: _confirmSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuery(String value) {
    _canApplyInitialCurrentLocation = false;
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      _clearSearchState(cancelRequest: true);
      return;
    }

    setState(() {
      _showSearchSuggestions = true;
      _searchSuggestions = const [];
      _searchMessage = null;
    });

    if (query.length < 2) {
      _searchCancelToken?.cancel('Search query is too short.');
      _searchRequestId++;
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      _searchLocations(query);
    });
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.length < 2) return;

    _unfocusSearch();
    _searchLocations(query);
  }

  void _handleMapIdle(LatLng point) {
    _canApplyInitialCurrentLocation = false;
    _hideSearchSuggestions();
    _unfocusSearch();
    _setPendingMapPoint(point);
    _resolveAddress(point);
  }

  Future<void> _centerMapOnCurrentLocation() async {
    final canUseLocation = await _prepareLocationAccess();
    if (!mounted || !canUseLocation || !_canApplyInitialCurrentLocation) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted || !_canApplyInitialCurrentLocation) return;

      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 16);
      _setPendingMapPoint(point);
      _resolveAddress(point);
    } catch (_) {}
  }

  Future<bool> _prepareLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _searchLocations(String query) async {
    _searchCancelToken?.cancel('A newer location search was submitted.');
    _reverseGeocodingCancelToken?.cancel('Location search started.');
    final requestId = ++_searchRequestId;
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    setState(() {
      _isSearchingLocations = true;
      _showSearchSuggestions = true;
      _searchSuggestions = const [];
      _searchMessage = null;
    });

    try {
      final suggestions = await _reverseGeocodingService.searchLocations(
        query,
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _isSearchingLocations = false;
        _searchSuggestions = suggestions;
        _searchMessage = suggestions.isEmpty ? 'Lokasi tidak ditemukan' : null;
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      _showSearchError(requestId);
    } catch (_) {
      _showSearchError(requestId);
    }
  }

  void _showSearchError(int requestId) {
    if (!mounted || requestId != _searchRequestId) return;

    setState(() {
      _isSearchingLocations = false;
      _showSearchSuggestions = true;
      _searchSuggestions = const [];
      _searchMessage = 'Pencarian lokasi tidak tersedia';
    });
  }

  void _selectSearchSuggestion(ForwardGeocodedLocation suggestion) {
    _canApplyInitialCurrentLocation = false;
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('A location suggestion was selected.');
    _searchRequestId++;
    _reverseGeocodingCancelToken?.cancel(
      'Location search selected a new place.',
    );
    _searchController.text = suggestion.name;
    _searchController.selection = TextSelection.collapsed(
      offset: suggestion.name.length,
    );
    _mapController.move(suggestion.point, 16);
    _unfocusSearch();

    setState(() {
      _isSearchingLocations = false;
      _isResolvingAddress = false;
      _showSearchSuggestions = false;
      _searchSuggestions = const [];
      _searchMessage = null;
      _selectedPlace = _selectedPlaceFrom(
        suggestion.point,
        name: suggestion.name,
        address: suggestion.address,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _clearSearchState(cancelRequest: true);
  }

  void _clearSearchState({required bool cancelRequest}) {
    _searchDebounce?.cancel();
    if (cancelRequest) {
      _searchCancelToken?.cancel('Location search cleared.');
      _searchRequestId++;
    }

    setState(() {
      _isSearchingLocations = false;
      _showSearchSuggestions = false;
      _searchSuggestions = const [];
      _searchMessage = null;
    });
  }

  void _hideSearchSuggestions() {
    if (!_showSearchSuggestions &&
        !_isSearchingLocations &&
        _searchSuggestions.isEmpty &&
        _searchMessage == null) {
      return;
    }

    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Location suggestions hidden.');
    _searchRequestId++;

    setState(() {
      _showSearchSuggestions = false;
      _isSearchingLocations = false;
      _searchSuggestions = const [];
      _searchMessage = null;
    });
  }

  void _dismissSearchOverlay() {
    _unfocusSearch();
    _hideSearchSuggestions();
  }

  void _setPendingMapPoint(LatLng point) {
    setState(() {
      _isResolvingAddress = true;
      _selectedPlace = LocationMapPlace(
        location: LocationItem(
          name: 'Pinned location',
          address: 'Finding address...',
          distanceLabel: '0.0km',
          latitude: point.latitude,
          longitude: point.longitude,
        ),
        type: LocationMapPlaceType.selected,
      );
    });
  }

  Future<void> _resolveAddress(LatLng point) async {
    _reverseGeocodingCancelToken?.cancel('A newer map center was selected.');
    final requestId = ++_reverseGeocodingRequestId;
    final cancelToken = CancelToken();
    _reverseGeocodingCancelToken = cancelToken;

    try {
      final result = await _reverseGeocodingService.reverseGeocode(
        point,
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _reverseGeocodingRequestId) return;

      setState(() {
        _isResolvingAddress = false;
        _selectedPlace = _selectedPlaceFrom(
          point,
          name: result.name,
          address: result.address,
        );
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      _showCoordinateFallback(point, requestId);
    } catch (_) {
      _showCoordinateFallback(point, requestId);
    }
  }

  void _showCoordinateFallback(LatLng point, int requestId) {
    if (!mounted || requestId != _reverseGeocodingRequestId) return;

    setState(() {
      _isResolvingAddress = false;
      _selectedPlace = _selectedPlaceFrom(
        point,
        name: 'Pinned location',
        address: _formatCoordinates(point),
      );
    });
  }

  LocationMapPlace _selectedPlaceFrom(
    LatLng point, {
    required String name,
    required String address,
  }) {
    return LocationMapPlace(
      location: LocationItem(
        name: name,
        address: address,
        distanceLabel: '0.0km',
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      type: LocationMapPlaceType.selected,
    );
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
  }

  void _confirmSelection() {
    _unfocusSearch();

    if (context.canPop()) {
      context.pop(_selectedPlace.location);
      return;
    }

    context.goNamed('home');
  }

  void _unfocusSearch() {
    FocusScope.of(context).unfocus();
  }
}

class _LocationSearchSuggestions extends StatelessWidget {
  const _LocationSearchSuggestions({
    required this.isLoading,
    required this.message,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final bool isLoading;
  final String? message;
  final List<ForwardGeocodedLocation> suggestions;
  final ValueChanged<ForwardGeocodedLocation> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const _LocationSearchStatus(message: 'Mencari lokasi...')
        : message != null
        ? _LocationSearchStatus(message: message!)
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.07),
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _LocationSearchSuggestionTile(
                suggestion: suggestion,
                onTap: () => onSuggestionTap(suggestion),
              );
            },
          );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 292),
        child: content,
      ),
    );
  }
}

class _LocationSearchStatus extends StatelessWidget {
  const _LocationSearchStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (message == 'Mencari lokasi...') ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSearchSuggestionTile extends StatelessWidget {
  const _LocationSearchSuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final ForwardGeocodedLocation suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      height: 1.25,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSelectionSheet extends StatelessWidget {
  const _LocationSelectionSheet({
    required this.location,
    required this.isResolvingAddress,
    required this.onSelect,
  });

  final LocationItem location;
  final bool isResolvingAddress;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(34, 34, 34, 28),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select location',
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: isResolvingAddress
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          location.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            height: 1.25,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                    textStyle: AppTextStyles.button.copyWith(
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                  child: Text(
                    'Select',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
