import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/admin_remote_data_source.dart';
import '../../../admin/data/models/admin_food.dart';
import '../../../admin/data/models/admin_merchant.dart';
import '../../../admin/presentation/screens/admin_add_menu_screen.dart';
import '../../../admin/presentation/screens/admin_menu_detail_screen.dart';
import '../../../food/data/models/food_detail.dart';
import '../../../food/presentation/screens/food_merchant_detail_screen.dart';

enum _MerchantMenuFilter { all, active, inactive }

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late final AdminRemoteDataSource _remoteDataSource;
  late Future<_MerchantDashboardData> _dashboardFuture;
  final TextEditingController _searchController = TextEditingController();

  List<AdminFood> _foods = const [];
  AdminMerchant? _merchant;
  String _query = '';
  _MerchantMenuFilter _selectedFilter = _MerchantMenuFilter.all;
  String? _updatingFoodId;
  String? _deletingFoodId;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
    _dashboardFuture = _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_MerchantDashboardData> _loadDashboard() async {
    final results = await Future.wait<Object>([
      _remoteDataSource.getOwnMerchant(),
      _remoteDataSource.getOwnFoods(),
    ]);
    final merchant = results[0] as AdminMerchant;
    final foods = results[1] as List<AdminFood>;

    if (mounted) {
      setState(() {
        _merchant = merchant;
        _foods = foods;
      });
    }

    return _MerchantDashboardData(merchant: merchant, foods: foods);
  }

  Future<void> _refreshDashboard() async {
    final nextFuture = _loadDashboard();
    setState(() => _dashboardFuture = nextFuture);
    try {
      await nextFuture;
    } catch (_) {}
  }

  List<AdminFood> get _visibleFoods {
    return _foods
        .where((food) {
          final matchesQuery =
              _query.isEmpty || food.name.toLowerCase().contains(_query);
          final matchesFilter = switch (_selectedFilter) {
            _MerchantMenuFilter.all => true,
            _MerchantMenuFilter.active => food.isAvailable,
            _MerchantMenuFilter.inactive => !food.isAvailable,
          };

          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  Future<void> _setFoodAvailability(AdminFood food, bool value) async {
    if (_updatingFoodId != null) return;

    final previousFoods = _foods;
    setState(() {
      _updatingFoodId = food.id;
      _foods = _foods
          .map(
            (item) =>
                item.id == food.id ? item.copyWith(isAvailable: value) : item,
          )
          .toList(growable: false);
    });

    try {
      await _remoteDataSource.updateOwnFoodAvailability(
        foodId: food.id,
        isAvailable: value,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _foods = previousFoods);
      _showToast('Gagal mengubah status menu.', isError: true);
    } finally {
      if (mounted) setState(() => _updatingFoodId = null);
    }
  }

  Future<void> _deleteFood(AdminFood food) async {
    if (_deletingFoodId != null) return;

    final previousFoods = _foods;
    setState(() {
      _deletingFoodId = food.id;
      _foods = _foods
          .where((item) => item.id != food.id)
          .toList(growable: false);
    });

    try {
      await _remoteDataSource.deleteOwnFood(food.id);
      if (!mounted) return;
      _showToast('Menu berhasil dihapus.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _foods = previousFoods);
      _showToast('Gagal menghapus menu. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _deletingFoodId = null);
    }
  }

  Future<void> _openMenuDetail(AdminFood food) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) =>
            AdminMenuDetailScreen(food: food, useMerchantEndpoint: true),
      ),
    );
    if (!mounted) return;

    if (result == 'delete') {
      await _deleteFood(food);
      return;
    }

    if (result == true) await _refreshDashboard();
  }

  Future<void> _openAddMenu() async {
    final merchant = _merchant;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AdminAddMenuScreen(
          merchantId: merchant?.id ?? 'me',
          merchantName: _displayMerchantName,
          useMerchantEndpoint: true,
        ),
      ),
    );
    if (created != true || !mounted) return;

    _showToast('Menu berhasil ditambahkan.');
    await _refreshDashboard();
  }

  Future<void> _openMerchantProfile() async {
    final merchant = _merchant;
    if (merchant == null) {
      _showToast('Profil merchant belum bisa dimuat.', isError: true);
      return;
    }

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => FoodMerchantDetailScreen(
          merchant: FoodMerchantDetail(
            name: merchant.name,
            email: merchant.email,
            address: merchant.address,
            photoUrl: '',
            latitude: merchant.latitude,
            longitude: merchant.longitude,
          ),
          onSaveChanges: _saveMerchantProfile,
          onLogout: _handleMerchantLogout,
        ),
      ),
    );
    if (!mounted) return;

    if (result is FoodMerchantDetail) {
      setState(() {
        _merchant = AdminMerchant(
          id: merchant.id,
          name: result.name,
          address: result.address,
          isActive: merchant.isActive,
          email: result.email,
          latitude: result.latitude,
          longitude: result.longitude,
        );
      });
    }
  }

  Future<FoodMerchantDetail> _saveMerchantProfile(
    FoodMerchantDetail updated,
    String? _,
  ) async {
    final currentMerchant = _merchant;
    if (currentMerchant == null) {
      throw StateError('Profil merchant belum dimuat.');
    }

    final saved = await _remoteDataSource.updateOwnMerchant(
      id: currentMerchant.id,
      name: updated.name,
      address: updated.address,
      email: updated.email,
      latitude: updated.latitude,
      longitude: updated.longitude,
    );

    if (mounted) setState(() => _merchant = saved);

    return FoodMerchantDetail(
      name: saved.name,
      email: saved.email.isNotEmpty ? saved.email : updated.email,
      address: saved.address,
      photoUrl: updated.photoUrl,
      latitude: saved.latitude ?? updated.latitude,
      longitude: saved.longitude ?? updated.longitude,
    );
  }

  Future<void> _handleMerchantLogout() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      GoogleSignIn().signOut(),
    ]);
    await _secureStorage.delete(key: ApiConstants.firebaseIdTokenStorageKey);

    if (!mounted) return;
    context.goNamed(AppRouter.login);
  }

  String get _displayMerchantName {
    final name = _merchant?.name.trim() ?? '';
    return name.isEmpty ? 'Merchant' : name;
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: FloatingActionButton(
        heroTag: 'merchant-add-menu',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        onPressed: _openAddMenu,
        child: const Icon(Icons.add_rounded, size: 38),
      ),
      body: SafeArea(
        child: FutureBuilder<_MerchantDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final foods = _foods.isEmpty ? data?.foods ?? const [] : _foods;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                foods.isEmpty;
            final error = snapshot.hasError && foods.isEmpty
                ? snapshot.error
                : null;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshDashboard,
              child: _MerchantHomeContent(
                foods: _visibleFoods,
                totalActiveItems: _foods
                    .where((food) => food.isAvailable)
                    .length,
                totalInactiveItems: _foods
                    .where((food) => !food.isAvailable)
                    .length,
                selectedFilter: _selectedFilter,
                isLoading: isLoading,
                error: error,
                searchController: _searchController,
                updatingFoodId: _updatingFoodId,
                onSearchChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
                onProfileTap: _openMerchantProfile,
                onDetail: _openMenuDetail,
                onAvailabilityChanged: _setFoodAvailability,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MerchantDashboardData {
  const _MerchantDashboardData({required this.merchant, required this.foods});

  final AdminMerchant merchant;
  final List<AdminFood> foods;
}

class _MerchantHomeContent extends StatelessWidget {
  const _MerchantHomeContent({
    required this.foods,
    required this.totalActiveItems,
    required this.totalInactiveItems,
    required this.selectedFilter,
    required this.isLoading,
    required this.error,
    required this.searchController,
    required this.updatingFoodId,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onProfileTap,
    required this.onDetail,
    required this.onAvailabilityChanged,
  });

  final List<AdminFood> foods;
  final int totalActiveItems;
  final int totalInactiveItems;
  final _MerchantMenuFilter selectedFilter;
  final bool isLoading;
  final Object? error;
  final TextEditingController searchController;
  final String? updatingFoodId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_MerchantMenuFilter> onFilterChanged;
  final VoidCallback onProfileTap;
  final ValueChanged<AdminFood> onDetail;
  final void Function(AdminFood food, bool value) onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/Logo - Green.svg',
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF202020),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Merchant',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF202020),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _MerchantProfileButton(onTap: onProfileTap),
            ],
          ),
          const SizedBox(height: 32),
          _MerchantSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MerchantStatCard(
                  title: 'Total Active Menu',
                  value: totalActiveItems,
                  color: const Color(0xFF368D3A),
                  icon: Icons.room_service_rounded,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _MerchantStatCard(
                  title: 'Total Inactive Menu',
                  value: totalInactiveItems,
                  color: const Color(0xFFCC181D),
                  icon: Icons.no_food_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 66,
                child: _MerchantFilterChip(
                  label: 'All',
                  selected: selectedFilter == _MerchantMenuFilter.all,
                  onTap: () => onFilterChanged(_MerchantMenuFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MerchantFilterChip(
                  label: 'Active Menu',
                  selected: selectedFilter == _MerchantMenuFilter.active,
                  onTap: () => onFilterChanged(_MerchantMenuFilter.active),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MerchantFilterChip(
                  label: 'Inactive Menu',
                  selected: selectedFilter == _MerchantMenuFilter.inactive,
                  onTap: () => onFilterChanged(_MerchantMenuFilter.inactive),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading)
            const _MerchantMenuListSkeleton()
          else if (error != null)
            const _MerchantListStatus(message: 'Failed to load menu.')
          else if (foods.isEmpty)
            const _MerchantListStatus(message: 'No menu available.')
          else
            ...foods.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MerchantMenuTile(
                  food: food,
                  isUpdating: updatingFoodId == food.id,
                  onDetail: () => onDetail(food),
                  onAvailabilityChanged: (value) {
                    onAvailabilityChanged(food, value);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MerchantProfileButton extends StatelessWidget {
  const _MerchantProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.person_rounded, color: Colors.white, size: 33),
        ),
      ),
    );
  }
}

class _MerchantSearchField extends StatelessWidget {
  const _MerchantSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF303030),
        ),
        decoration: InputDecoration(
          hintText: 'Search menu',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF111111),
            size: 22,
          ),
          filled: true,
          fillColor: const Color(0xFFDADADA),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _MerchantStatCard extends StatelessWidget {
  const _MerchantStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white.withValues(alpha: 0.72), size: 36),
            ],
          ),
        ],
      ),
    );
  }
}

class _MerchantFilterChip extends StatelessWidget {
  const _MerchantFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Material(
        color: selected ? const Color(0xFF3A7746) : const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(999),
        elevation: selected ? 2 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF4D4D4D),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MerchantMenuTile extends StatelessWidget {
  const _MerchantMenuTile({
    required this.food,
    required this.isUpdating,
    required this.onDetail,
    required this.onAvailabilityChanged,
  });

  final AdminFood food;
  final bool isUpdating;
  final VoidCallback onDetail;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          _MerchantFoodImage(imageUrl: food.imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF242424),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _AvailabilitySwitch(
                        value: food.isAvailable,
                        enabled: !isUpdating,
                        onChanged: onAvailabilityChanged,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        food.isAvailable ? 'Available' : 'Hidden',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 47,
            height: 28,
            child: ElevatedButton(
              onPressed: onDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Detail',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantFoodImage extends StatelessWidget {
  const _MerchantFoodImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 90,
        height: 90,
        child: imageUrl.trim().isEmpty
            ? const _FoodImagePlaceholder()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const AppSkeleton(child: _FoodImagePlaceholder()),
                errorWidget: (context, url, error) =>
                    const _FoodImagePlaceholder(),
              ),
      ),
    );
  }
}

class _FoodImagePlaceholder extends StatelessWidget {
  const _FoodImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFDCC6A5),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: AppColors.primary,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF3A7746) : const Color(0xFFCFCFCF),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantListStatus extends StatelessWidget {
  const _MerchantListStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4B4B4B),
        ),
      ),
    );
  }
}

class _MerchantMenuListSkeleton extends StatelessWidget {
  const _MerchantMenuListSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: List.generate(
          6,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                AppSkeletonBox(width: 90, height: 90, borderRadius: 8),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonLine(width: 130, height: 18),
                      SizedBox(height: 10),
                      AppSkeletonLine(width: 72, height: 12),
                      SizedBox(height: 14),
                      AppSkeletonLine(width: 118, height: 22),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                AppSkeletonBox(width: 47, height: 28, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
