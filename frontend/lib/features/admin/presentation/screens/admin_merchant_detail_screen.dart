import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../food/data/models/food_detail.dart';
import '../../../food/presentation/screens/food_merchant_detail_screen.dart';
import '../../data/admin_remote_data_source.dart';
import '../../data/models/admin_food.dart';
import '../../data/models/admin_merchant.dart';
import 'admin_add_menu_screen.dart';
import 'admin_menu_detail_screen.dart';

enum _MenuFilter { all, active, inactive }

class AdminMerchantDetailScreen extends StatefulWidget {
  const AdminMerchantDetailScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.merchant,
  });

  final String merchantId;
  final String merchantName;
  final AdminMerchant? merchant;

  @override
  State<AdminMerchantDetailScreen> createState() =>
      _AdminMerchantDetailScreenState();
}

class _AdminMerchantDetailScreenState extends State<AdminMerchantDetailScreen> {
  late final AdminRemoteDataSource _remoteDataSource;
  late Future<List<AdminFood>> _foodsFuture;
  final TextEditingController _searchController = TextEditingController();

  List<AdminFood> _foods = const [];
  AdminMerchant? _merchantOverride;
  String _query = '';
  _MenuFilter _selectedFilter = _MenuFilter.all;
  String? _updatingFoodId;
  String? _deletingFoodId;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
    _merchantOverride = widget.merchant;
    _foodsFuture = _loadFoods();
    _loadMerchantDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AdminFood>> _loadFoods() async {
    final foods = await _remoteDataSource.getMerchantFoods(widget.merchantId);
    if (mounted) setState(() => _foods = foods);
    return foods;
  }

  Future<void> _loadMerchantDetails() async {
    try {
      final merchant = await _remoteDataSource.getMerchant(widget.merchantId);
      if (mounted) setState(() => _merchantOverride = merchant);
    } catch (_) {}
  }

  Future<void> _refreshFoods() async {
    final nextFuture = _loadFoods();
    setState(() => _foodsFuture = nextFuture);
    try {
      await nextFuture;
    } catch (_) {}
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
      await _remoteDataSource.updateFoodAvailability(
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

    final confirmed = await _confirmDeleteFood(food.name);
    if (confirmed != true || !mounted) return;

    final previousFoods = _foods;
    setState(() {
      _deletingFoodId = food.id;
      _foods = _foods
          .where((item) => item.id != food.id)
          .toList(growable: false);
    });

    try {
      await _remoteDataSource.deleteFood(food.id);
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

  Future<bool?> _confirmDeleteFood(String foodName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus menu?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Menu "$foodName" akan dihapus dari merchant ini.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF606060),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFCC1B1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin-add-menu',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: _openAddMenu,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
      body: SafeArea(
        child: FutureBuilder<List<AdminFood>>(
          future: _foodsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                _foods.isEmpty;
            final error = snapshot.hasError && _foods.isEmpty
                ? snapshot.error
                : null;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshFoods,
              child: _AdminMerchantDetailContent(
                merchantName: _displayMerchantName,
                foods: _visibleFoods,
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
                onBack: () => context.pop(),
                onMerchantProfile: _openMerchantProfile,
                onDetail: _openMenuDetail,
                onAvailabilityChanged: _setFoodAvailability,
              ),
            );
          },
        ),
      ),
    );
  }

  String get _displayMerchantName {
    final name = _currentMerchant?.name ?? widget.merchantName;
    return name.trim().isEmpty ? 'Merchant' : name;
  }

  AdminMerchant? get _currentMerchant => _merchantOverride ?? widget.merchant;

  List<AdminFood> get _visibleFoods {
    return _foods
        .where((food) {
          final matchesQuery =
              _query.isEmpty || food.name.toLowerCase().contains(_query);
          final matchesFilter = switch (_selectedFilter) {
            _MenuFilter.all => true,
            _MenuFilter.active => food.isAvailable,
            _MenuFilter.inactive => !food.isAvailable,
          };

          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
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
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _openMenuDetail(AdminFood food) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AdminMenuDetailScreen(food: food),
      ),
    );
    if (!mounted) return;

    if (result == 'delete') {
      await _deleteFood(food);
      return;
    }

    if (result == true) await _refreshFoods();
  }

  Future<void> _openMerchantProfile() async {
    final merchant = _currentMerchant;

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => FoodMerchantDetailScreen(
          merchant: FoodMerchantDetail(
            name: _displayMerchantName,
            email: merchant?.email ?? '',
            address: merchant?.address ?? '',
            photoUrl: '',
            latitude: merchant?.latitude,
            longitude: merchant?.longitude,
          ),
          onSaveChanges: _saveMerchantProfile,
          onDelete: _deleteMerchant,
        ),
      ),
    );

    if (!mounted) return;
    if (result == 'delete' || result == 'hide') context.pop(result);
  }

  Future<bool> _deleteMerchant() {
    return _remoteDataSource.deleteMerchant(widget.merchantId);
  }

  Future<FoodMerchantDetail> _saveMerchantProfile(
    FoodMerchantDetail updated,
    String? newPassword,
  ) async {
    final currentMerchant = _currentMerchant;
    final savedMerchant = await _remoteDataSource.updateMerchant(
      id: widget.merchantId,
      name: updated.name,
      address: updated.address,
      isActive: currentMerchant?.isActive ?? true,
      email: updated.email,
      password: newPassword,
      latitude: updated.latitude,
      longitude: updated.longitude,
    );

    if (mounted) setState(() => _merchantOverride = savedMerchant);

    return FoodMerchantDetail(
      name: savedMerchant.name,
      email: savedMerchant.email.isNotEmpty
          ? savedMerchant.email
          : updated.email,
      address: savedMerchant.address,
      photoUrl: updated.photoUrl,
      latitude: savedMerchant.latitude ?? updated.latitude,
      longitude: savedMerchant.longitude ?? updated.longitude,
    );
  }

  Future<void> _openAddMenu() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AdminAddMenuScreen(
          merchantId: widget.merchantId,
          merchantName: _displayMerchantName,
        ),
      ),
    );
    if (created != true || !mounted) return;

    _showToast('Menu berhasil ditambahkan.');
    await _refreshFoods();
  }
}

class _AdminMerchantDetailContent extends StatelessWidget {
  const _AdminMerchantDetailContent({
    required this.merchantName,
    required this.foods,
    required this.selectedFilter,
    required this.isLoading,
    required this.error,
    required this.searchController,
    required this.updatingFoodId,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onBack,
    required this.onMerchantProfile,
    required this.onDetail,
    required this.onAvailabilityChanged,
  });

  final String merchantName;
  final List<AdminFood> foods;
  final _MenuFilter selectedFilter;
  final bool isLoading;
  final Object? error;
  final TextEditingController searchController;
  final String? updatingFoodId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_MenuFilter> onFilterChanged;
  final VoidCallback onBack;
  final VoidCallback onMerchantProfile;
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
          _DetailHeader(
            merchantName: merchantName,
            onBack: onBack,
            onMerchantTap: onMerchantProfile,
          ),
          const SizedBox(height: 24),
          _MenuSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 18),
          _MenuFilterBar(
            selectedFilter: selectedFilter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const _MenuListSkeleton()
          else if (error != null)
            const _MenuStatus(message: 'Failed to load menu.')
          else if (foods.isEmpty)
            const _MenuStatus(message: 'No menu found.')
          else
            ...foods.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MenuItemTile(
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.merchantName,
    required this.onBack,
    required this.onMerchantTap,
  });

  final String merchantName;
  final VoidCallback onBack;
  final VoidCallback onMerchantTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 30,
            color: Color(0xFF202020),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            merchantName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF202020),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Buka data merchant $merchantName',
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onMerchantTap,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSearchField extends StatelessWidget {
  const _MenuSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF303030),
        ),
        decoration: InputDecoration(
          hintText: 'Search menu',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF111111),
            size: 24,
          ),
          filled: true,
          fillColor: const Color(0xFFDCDCDC),
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

class _MenuFilterBar extends StatelessWidget {
  const _MenuFilterBar({required this.selectedFilter, required this.onChanged});

  final _MenuFilter selectedFilter;
  final ValueChanged<_MenuFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: _MenuFilterChip(
            label: 'All',
            isSelected: selectedFilter == _MenuFilter.all,
            onTap: () => onChanged(_MenuFilter.all),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MenuFilterChip(
            label: 'Active Menu',
            isSelected: selectedFilter == _MenuFilter.active,
            onTap: () => onChanged(_MenuFilter.active),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MenuFilterChip(
            label: 'Inactive Menu',
            isSelected: selectedFilter == _MenuFilter.inactive,
            onTap: () => onChanged(_MenuFilter.inactive),
          ),
        ),
      ],
    );
  }
}

class _MenuFilterChip extends StatelessWidget {
  const _MenuFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Material(
        color: isSelected ? const Color(0xFF3B7047) : const Color(0xFFF4F2F2),
        borderRadius: BorderRadius.circular(999),
        elevation: isSelected ? 2 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF4D4D4D),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
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
      height: 76,
      child: Row(
        children: [
          _MenuImage(imageUrl: food.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        isUpdating: isUpdating,
                        onChanged: onAvailabilityChanged,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        food.isAvailable ? 'Available' : 'Hidden',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3F3F3F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MenuActionButton(label: 'Detail', onPressed: onDetail),
        ],
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: imageUrl.isEmpty
            ? const _MenuImageFallback()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const _MenuImageFallback(),
                errorWidget: (context, url, error) =>
                    const _MenuImageFallback(),
              ),
      ),
    );
  }
}

class _MenuImageFallback extends StatelessWidget {
  const _MenuImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE7EFE8)),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({
    required this.value,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool value;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isUpdating ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF3B7047) : const Color(0xFFC8C8C8),
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

class _MenuActionButton extends StatelessWidget {
  const _MenuActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 26,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MenuStatus extends StatelessWidget {
  const _MenuStatus({required this.message});

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
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuListSkeleton extends StatelessWidget {
  const _MenuListSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: List.generate(
          7,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _MenuTileSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _MenuTileSkeleton extends StatelessWidget {
  const _MenuTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Row(
        children: [
          AppSkeletonBox(width: 76, height: 76, borderRadius: 8),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonLine(width: 120, height: 15),
                  SizedBox(height: 8),
                  AppSkeletonLine(width: 68, height: 12),
                  Spacer(),
                  Row(
                    children: [
                      AppSkeletonLine(width: 34, height: 18, borderRadius: 9),
                      SizedBox(width: 8),
                      AppSkeletonLine(width: 62, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          AppSkeletonBox(width: 58, height: 26, borderRadius: 6),
        ],
      ),
    );
  }
}
