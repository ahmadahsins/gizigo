import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/services/auto_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../router/app_router.dart';
import '../../data/location_remote_data_source.dart';
import '../../data/location_reverse_geocoding_service.dart';
import '../../data/location_storage_service.dart';
import '../../domain/entities/location_item.dart';
import '../widgets/location_action_chip.dart';
import '../widgets/location_recent_tile.dart';
import '../widgets/location_search_field.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  static const double _wideHorizontalPadding = 34;
  static const double _compactHorizontalPadding = 24;

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen>
    with AutoRefreshStateMixin<SelectLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LocationReverseGeocodingService _geocodingService =
      LocationReverseGeocodingService();
  final LocationStorageService _locationStorage =
      const LocationStorageService();
  late final LocationRemoteDataSource _locationRemoteDataSource;

  String _query = '';
  List<LocationItem> _recentLocations = const [];
  List<LocationItem> _searchResults = const [];
  Timer? _searchDebounce;
  CancelToken? _searchCancelToken;
  int _searchRequestId = 0;
  bool _isSearching = false;
  bool _isUsingCurrentLocation = false;
  bool _isLoadingRecentLocations = true;
  String? _searchMessage;

  List<LocationItem> get _visibleLocations {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return _recentLocations;

    return _searchResults;
  }

  bool get _hasQuery => _query.trim().isNotEmpty;

  String get _sectionTitle => _hasQuery ? 'Search results' : 'Recent';

  String get _emptyMessage {
    if (_isSearching || _isLoadingRecentLocations) return 'Mencari lokasi...';
    if (_searchMessage != null) return _searchMessage!;
    return _hasQuery ? 'Lokasi tidak ditemukan' : 'No recent locations';
  }

  @override
  void initState() {
    super.initState();
    _locationRemoteDataSource = LocationRemoteDataSource(DioClient());
    _loadRecentLocations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationServiceEnabled();
    });
  }

  @override
  bool get canAutoRefresh {
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        !_hasQuery &&
        !_isUsingCurrentLocation;
  }

  @override
  Future<void> onAutoRefresh() {
    return _loadRecentLocations(showLoading: false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Select location screen disposed.');
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _horizontalPaddingFor(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _unfocusSearch,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LocationHeader(onBack: _handleBack),
                          const SizedBox(height: 18),
                          LocationSearchField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _updateQuery,
                            hasText: _hasQuery,
                            onClear: _clearSearch,
                            onTapOutside: _unfocusSearch,
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                LocationActionChip(
                                  icon: _isUsingCurrentLocation
                                      ? Icons.sync_rounded
                                      : Icons.my_location_rounded,
                                  iconColor: const Color(0xFFFF7A1A),
                                  label: _isUsingCurrentLocation
                                      ? 'Finding location'
                                      : 'Your current location',
                                  onTap: _useCurrentLocation,
                                ),
                                const SizedBox(width: 12),
                                LocationActionChip(
                                  icon: Icons.map_rounded,
                                  iconColor: const Color(0xFF5D9CFF),
                                  label: 'Select on map',
                                  onTap: _selectOnMap,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _sectionTitle,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver:
                        _visibleLocations.isEmpty ||
                            _isSearching ||
                            _isLoadingRecentLocations
                        ? SliverToBoxAdapter(
                            child: _EmptyLocations(
                              message: _emptyMessage,
                              isLoading:
                                  _isSearching || _isLoadingRecentLocations,
                            ),
                          )
                        : SliverList.separated(
                            itemBuilder: (context, index) {
                              final location = _visibleLocations[index];

                              return LocationRecentTile(
                                location: location,
                                onTap: () => _selectLocation(location),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 2),
                            itemCount: _visibleLocations.length,
                          ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateQuery(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      _clearSearchState(cancelRequest: true);
      return;
    }

    setState(() {
      _query = value;
      _searchResults = const [];
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

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed('home');
  }

  Future<void> _useCurrentLocation() async {
    if (_isUsingCurrentLocation) return;

    final canUseLocation = await _prepareLocationAccess();
    if (!mounted || !canUseLocation) return;

    setState(() => _isUsingCurrentLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      final geocodedLocation = await _geocodingService.reverseGeocode(point);

      if (!mounted) return;

      _selectLocation(
        LocationItem(
          name: geocodedLocation.name,
          address: geocodedLocation.address,
          distanceLabel: '0.0km',
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Gagal mengambil lokasi saat ini.');
    } finally {
      if (mounted) {
        setState(() => _isUsingCurrentLocation = false);
      }
    }
  }

  void _selectOnMap() {
    _unfocusSearch();
    _openMapSelection();
  }

  Future<void> _selectLocation(LocationItem location) async {
    _unfocusSearch();

    await _saveSelectedLocation(location);
    if (!mounted) return;

    if (context.canPop()) {
      context.pop(location);
      return;
    }

    context.goNamed('home');
  }

  void _unfocusSearch() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _loadRecentLocations({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoadingRecentLocations = true);
    }

    try {
      final locations = await _locationRemoteDataSource.getRecentLocations();
      if (!mounted) return;

      setState(() {
        _recentLocations = locations;
        _isLoadingRecentLocations = false;
      });
    } catch (_) {
      if (!mounted) return;

      if (showLoading || _recentLocations.isEmpty) {
        setState(() {
          _recentLocations = const [];
          _isLoadingRecentLocations = false;
        });
      }
    }
  }

  Future<void> _saveSelectedLocation(LocationItem location) async {
    await _locationStorage.saveSelectedLocation(location);

    try {
      await _locationRemoteDataSource.saveRecentLocation(location);
      AutoRefreshService.instance.refreshNow();
    } catch (_) {}
  }

  Future<void> _searchLocations(String query) async {
    _searchCancelToken?.cancel('A newer location search was submitted.');
    final requestId = ++_searchRequestId;
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    setState(() {
      _isSearching = true;
      _searchResults = const [];
      _searchMessage = null;
    });

    try {
      final remoteResults = await _geocodingService.searchLocations(
        query,
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _isSearching = false;
        _searchResults = remoteResults
            .map(
              (location) => LocationItem(
                name: location.name,
                address: location.address,
                distanceLabel: '0.0km',
                latitude: location.point.latitude,
                longitude: location.point.longitude,
              ),
            )
            .toList();
        _searchMessage = _searchResults.isEmpty
            ? 'Lokasi tidak ditemukan'
            : null;
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      _showSearchUnavailable(requestId);
    } catch (_) {
      _showSearchUnavailable(requestId);
    }
  }

  void _showSearchUnavailable(int requestId) {
    if (!mounted || requestId != _searchRequestId) return;

    setState(() {
      _isSearching = false;
      _searchResults = const [];
      _searchMessage = 'Pencarian lokasi tidak tersedia';
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
      _query = '';
      _isSearching = false;
      _searchResults = const [];
      _searchMessage = null;
    });
  }

  Future<void> _ensureLocationServiceEnabled() async {
    if (await Geolocator.isLocationServiceEnabled()) return;
    if (!mounted) return;

    await _showEnableLocationDialog();
  }

  Future<bool> _prepareLocationAccess() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (mounted) {
        await _showEnableLocationDialog();
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnackBar('Izin lokasi diperlukan untuk memakai lokasi saat ini.');
      }
      return false;
    }

    return true;
  }

  Future<void> _showEnableLocationDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nyalakan GPS'),
          content: const Text(
            'GiziGo perlu GPS aktif untuk memakai lokasi saat ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Nyalakan'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double _horizontalPaddingFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return SelectLocationScreen._compactHorizontalPadding;

    return SelectLocationScreen._wideHorizontalPadding;
  }

  Future<void> _openMapSelection() async {
    final selectedLocation = await context.pushNamed<LocationItem>(
      AppRouter.selectLocationMap,
    );
    if (!mounted || selectedLocation == null) return;

    _selectLocation(selectedLocation);
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(22),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 31,
                color: Color(0xFF202124),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Text(
          'Select location',
          style: AppTextStyles.heading3.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF242424),
          ),
        ),
      ],
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  const _EmptyLocations({required this.message, required this.isLoading});

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LocationLoadingList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationLoadingList extends StatelessWidget {
  const _LocationLoadingList();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonCircle(size: 38),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonLine(width: 190, height: 16),
                      SizedBox(height: 8),
                      AppSkeletonLine(height: 11),
                      SizedBox(height: 6),
                      AppSkeletonLine(width: 220, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
