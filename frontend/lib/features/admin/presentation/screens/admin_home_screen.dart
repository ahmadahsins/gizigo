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
import '../../data/admin_remote_data_source.dart';
import '../../data/models/admin_merchant.dart';
import 'admin_add_merchant_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late final AdminRemoteDataSource _remoteDataSource;
  late Future<AdminDashboardData> _dashboardFuture;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _deletedMerchantIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
    _dashboardFuture = _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<AdminDashboardData> _loadDashboardData() async {
    return _remoteDataSource.getDashboardData(
      excludedMerchantIds: _deletedMerchantIds,
    );
  }

  Future<void> _refreshDashboard() async {
    final nextFuture = _loadDashboardData();
    setState(() => _dashboardFuture = nextFuture);
    try {
      await nextFuture;
    } catch (_) {}
  }

  Future<void> _showMerchantLocally(AdminMerchant merchant) async {
    final currentData = await _dashboardFuture.catchError((_) {
      return const AdminDashboardData(
        merchants: [],
        totalMerchants: 0,
        totalActiveMenus: 0,
        totalInactiveMenus: 0,
      );
    });
    if (!mounted) return;

    final hasMerchant = currentData.merchants.any(
      (item) => item.id == merchant.id,
    );
    final merchants = hasMerchant
        ? currentData.merchants
        : [merchant, ...currentData.merchants];
    final totalMerchants = currentData.totalMerchants + (hasMerchant ? 0 : 1);

    setState(() {
      _dashboardFuture = Future.value(
        AdminDashboardData(
          merchants: merchants,
          totalMerchants: totalMerchants,
          totalActiveMenus: currentData.totalActiveMenus,
          totalInactiveMenus: currentData.totalInactiveMenus,
        ),
      );
    });
  }

  Future<void> _removeMerchantLocally(String merchantId) async {
    final currentData = await _dashboardFuture.catchError((_) {
      return const AdminDashboardData(
        merchants: [],
        totalMerchants: 0,
        totalActiveMenus: 0,
        totalInactiveMenus: 0,
      );
    });
    if (!mounted) return;

    final merchants = currentData.merchants
        .where((merchant) => merchant.id != merchantId)
        .toList(growable: false);

    setState(() {
      _dashboardFuture = Future.value(
        AdminDashboardData(
          merchants: merchants,
          totalMerchants: merchants.length,
          totalActiveMenus: currentData.totalActiveMenus,
          totalInactiveMenus: currentData.totalInactiveMenus,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin-add-merchant',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: _openAddMerchant,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
      body: SafeArea(
        child: FutureBuilder<AdminDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                data == null;
            final error = snapshot.hasError && data == null
                ? snapshot.error
                : null;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshDashboard,
              child: _AdminHomeContent(
                data: data,
                isLoading: isLoading,
                error: error,
                query: _query,
                searchController: _searchController,
                onSearchChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                onMerchantDetail: _openMerchantDetail,
                onLogoutTap: _handleLogoutTap,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogoutTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const _AdminLogoutConfirmationDialog(),
    );

    if (!mounted || confirmed != true) return;

    try {
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        GoogleSignIn().signOut(),
      ]);
      await _secureStorage.delete(key: ApiConstants.firebaseIdTokenStorageKey);

      if (!mounted) return;
      context.goNamed(AppRouter.login);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout gagal. Coba lagi.')));
    }
  }

  Future<void> _openAddMerchant() async {
    final merchant = await Navigator.of(context).push<AdminMerchant>(
      MaterialPageRoute(builder: (context) => const AdminAddMerchantScreen()),
    );
    if (merchant == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merchant berhasil ditambahkan.')),
    );
    await _showMerchantLocally(merchant);
    _refreshDashboard();
  }

  Future<void> _openMerchantDetail(AdminMerchant merchant) async {
    final result = await context.pushNamed<Object?>(
      AppRouter.adminMerchantDetail,
      pathParameters: {'id': merchant.id},
      queryParameters: {'name': merchant.name},
      extra: merchant,
    );

    if (!mounted) return;

    if (result != 'delete') {
      await _refreshDashboard();
      return;
    }

    _deletedMerchantIds.add(merchant.id);
    await _removeMerchantLocally(merchant.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merchant berhasil dihapus.')),
    );
    await _refreshDashboard();
  }
}

class _AdminHomeContent extends StatelessWidget {
  const _AdminHomeContent({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onMerchantDetail,
    required this.onLogoutTap,
  });

  final AdminDashboardData? data;
  final bool isLoading;
  final Object? error;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AdminMerchant> onMerchantDetail;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final dashboardData =
        data ??
        const AdminDashboardData(
          merchants: [],
          totalMerchants: 0,
          totalActiveMenus: 0,
          totalInactiveMenus: 0,
        );
    final merchants = _filteredMerchants(dashboardData.merchants);

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
                  child: SvgPicture.asset(
                    'assets/images/Logo - Green.svg',
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF202020),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _AdminLogoutBadge(onTap: onLogoutTap),
            ],
          ),
          const SizedBox(height: 32),
          _AdminSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          _AdminStatCard(
            title: 'Total Merchants',
            value: dashboardData.totalMerchants,
            color: const Color(0xFF385487),
            icon: Icons.storefront_rounded,
            isLarge: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Total Active Menu',
                  value: dashboardData.totalActiveMenus,
                  color: const Color(0xFF38873A),
                  icon: Icons.room_service_rounded,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _AdminStatCard(
                  title: 'Total Inactive Menu',
                  value: dashboardData.totalInactiveMenus,
                  color: const Color(0xFFC11B1B),
                  icon: Icons.no_food_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'Merchants',
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const _AdminMerchantListSkeleton()
          else if (error != null)
            const _AdminListStatus(message: 'Failed to load merchants.')
          else if (merchants.isEmpty)
            _AdminListStatus(
              message: query.isEmpty
                  ? 'No merchants available yet.'
                  : 'No merchants match your search.',
            )
          else
            ...merchants.map(
              (merchant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MerchantTile(
                  merchant: merchant,
                  onDetail: () => onMerchantDetail(merchant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<AdminMerchant> _filteredMerchants(List<AdminMerchant> merchants) {
    if (query.isEmpty) return merchants;

    return merchants
        .where((merchant) {
          return merchant.name.toLowerCase().contains(query) ||
              merchant.address.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }
}

class _AdminLogoutBadge extends StatelessWidget {
  const _AdminLogoutBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFC11B1B),
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({required this.controller, required this.onChanged});

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
          hintText: 'Search Merchant',
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

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isLarge = false,
  });

  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isLarge ? 100 : 100,
      padding: EdgeInsets.fromLTRB(
        isLarge ? 24 : 20,
        isLarge ? 18 : 14,
        isLarge ? 24 : 16,
        isLarge ? 18 : 14,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: isLarge ? 11 : 10.5,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.78),
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
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.72),
                size: isLarge ? 42 : 36,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  const _MerchantTile({required this.merchant, required this.onDetail});

  final AdminMerchant merchant;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const _MerchantStoreIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  merchant.address.isEmpty ? '-' : merchant.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF585858),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            height: 28,
            child: ElevatedButton(
              onPressed: onDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.16),
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

class _MerchantStoreIcon extends StatelessWidget {
  const _MerchantStoreIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 42,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBF2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF3D6779),
              size: 22,
            ),
          ),
          Positioned(
            top: 0,
            child: Row(
              children: List.generate(
                4,
                (index) => Container(
                  width: 10,
                  height: 12,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? const Color(0xFFFFC33B)
                        : const Color(0xFF3EA34C),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminListStatus extends StatelessWidget {
  const _AdminListStatus({required this.message});

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

class _AdminLogoutConfirmationDialog extends StatelessWidget {
  const _AdminLogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: const Color(0xFFFAF7F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFC11B1B),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Yakin ingin logout?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF242424),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sesi admin akan ditutup dan kamu perlu login kembali.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF666666),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFAF7F7),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC11B1B),
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: Colors.black.withValues(alpha: 0.22),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMerchantListSkeleton extends StatelessWidget {
  const _AdminMerchantListSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: List.generate(
          6,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _AdminMerchantTileSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _AdminMerchantTileSkeleton extends StatelessWidget {
  const _AdminMerchantTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          AppSkeletonBox(width: 48, height: 42, borderRadius: 6),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonLine(width: 136, height: 16),
                SizedBox(height: 8),
                AppSkeletonLine(height: 9),
              ],
            ),
          ),
          SizedBox(width: 10),
          AppSkeletonBox(width: 62, height: 28, borderRadius: 6),
        ],
      ),
    );
  }
}
