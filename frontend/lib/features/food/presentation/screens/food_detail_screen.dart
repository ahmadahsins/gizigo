import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/services/auto_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../home/presentation/widgets/rating_badge.dart';
import '../../data/food_remote_data_source.dart';
import '../../data/models/food_detail.dart';
import '../widgets/nutrition_rating_info_dialog.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.foodId});

  final String foodId;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen>
    with AutoRefreshStateMixin<FoodDetailScreen> {
  late final FoodRemoteDataSource _foodRemoteDataSource;

  FoodDetail? _food;
  Object? _error;
  bool _isLoading = true;
  bool _hasRecordedView = false;
  bool _isRecordingView = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _foodRemoteDataSource = FoodRemoteDataSource(DioClient());
    _loadFoodDetail();
  }

  @override
  Future<void> onAutoRefresh() {
    return _loadFoodDetail(showLoading: false, recordView: false);
  }

  @override
  Widget build(BuildContext context) {
    final food = _food;

    if (_isLoading && food == null) {
      return const Scaffold(body: _FoodDetailSkeleton());
    }

    if (food == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage(_error),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFoodDetail,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadFoodDetail(recordView: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _FoodHeroImage(imageUrl: food.imageUrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FoodDetailHeader(
                      food: food,
                      onRatingTap: () => showNutritionRatingInfoDialog(
                        context: context,
                        ratingText: food.ratingText,
                      ),
                    ),
                    if (food.healthLabels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _FoodHealthLabelRow(labels: food.healthLabels),
                    ],
                    const SizedBox(height: 24),
                    _DescriptionSection(description: food.description),
                    if (food.nutritionalInfo?.hasAnyValue == true) ...[
                      const SizedBox(height: 20),
                      _NutritionSummary(info: food.nutritionalInfo!),
                    ],
                    const SizedBox(height: 24),
                    _PriceComparisonSection(
                      food: food,
                      onComparisonTap: _openOrderUrl,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFoodDetail({
    bool showLoading = true,
    bool recordView = true,
  }) async {
    final loadGeneration = ++_loadGeneration;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final food = await _foodRemoteDataSource.getFoodDetail(widget.foodId);
      if (!mounted || loadGeneration != _loadGeneration) return;

      setState(() {
        _food = food;
        _error = null;
        _isLoading = false;
      });

      if (recordView) {
        _recordRecentlyViewed();
      }
    } catch (error) {
      if (!mounted || loadGeneration != _loadGeneration) return;

      if (showLoading || _food == null) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _recordRecentlyViewed() async {
    if (_hasRecordedView || _isRecordingView) return;
    _isRecordingView = true;

    try {
      await _foodRemoteDataSource.recordRecentlyViewed(widget.foodId);
      if (!mounted) return;

      _hasRecordedView = true;
      AutoRefreshService.instance.refreshNow();
    } catch (_) {
      // This is non-critical UI telemetry; detail loading should remain silent.
    } finally {
      _isRecordingView = false;
    }
  }

  Future<void> _openOrderUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showSnackBar('Link pemesanan tidak valid.');
      return;
    }

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch) {
        _showSnackBar('Link pemesanan belum bisa dibuka.');
      }
    } catch (_) {
      _showSnackBar('Link pemesanan belum bisa dibuka.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object? error) {
    if (error is DioException && error.response?.statusCode == 404) {
      return 'Makanan tidak ditemukan.';
    }

    return 'Detail makanan belum bisa dimuat. Cek koneksi atau backend, lalu coba lagi.';
  }
}

class _FoodDetailSkeleton extends StatelessWidget {
  const _FoodDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeletonBox(
              width: double.infinity,
              height: 280,
              borderRadius: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSkeletonLine(height: 24),
                            SizedBox(height: 10),
                            AppSkeletonLine(width: 160),
                            SizedBox(height: 10),
                            AppSkeletonLine(
                              width: 64,
                              height: 24,
                              borderRadius: 12,
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppSkeletonLine(
                                  width: 112,
                                  height: 34,
                                  borderRadius: 12,
                                ),
                                AppSkeletonLine(
                                  width: 104,
                                  height: 34,
                                  borderRadius: 12,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      AppSkeletonLine(width: 78, height: 18),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const AppSkeletonLine(width: 120, height: 18),
                  const SizedBox(height: 10),
                  const AppSkeletonLine(height: 12),
                  const SizedBox(height: 8),
                  const AppSkeletonLine(height: 12),
                  const SizedBox(height: 8),
                  const AppSkeletonLine(width: 230, height: 12),
                  const SizedBox(height: 28),
                  const AppSkeletonLine(width: 150, height: 18),
                  const SizedBox(height: 12),
                  const AppSkeletonBox(height: 76, borderRadius: 8),
                  const SizedBox(height: 10),
                  const AppSkeletonBox(height: 76, borderRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetailHeader extends StatelessWidget {
  const _FoodDetailHeader({
    required this.food,
    required this.onRatingTap,
  });

  final FoodDetail food;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                food.merchant.displayName(fallback: food.vendorName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.2,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              RatingBadge(text: food.ratingText, onTap: onRatingTap),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          food.formattedPrice,
          textAlign: TextAlign.end,
          style: GoogleFonts.inter(
            fontSize: 21,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _FoodHealthLabelRow extends StatelessWidget {
  const _FoodHealthLabelRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final displayLabels = labels
        .map(_FoodHealthLabel.displayTextFor)
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (displayLabels.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final label in displayLabels)
              SizedBox(
                width: itemWidth,
                child: _FoodHealthLabel(label),
              ),
          ],
        );
      },
    );
  }
}

class _FoodHealthLabel extends StatelessWidget {
  const _FoodHealthLabel(this.label);

  static const EdgeInsetsGeometry _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );

  final String label;

  static String displayTextFor(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final normalized = _normalizedKey(text);
    return switch (normalized) {
      'highprotein' => 'High Protein',
      'vegetarian' || 'vegan' => 'Vegetarian',
      'lowcalorie' || 'lowcalories' => 'Low Calories',
      'glutenfree' => 'Gluten Free',
      _ =>
        text
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
                  '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
            )
            .join(' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _FoodHealthLabelColors.forLabel(label);

    return Semantics(
      label: label,
      child: Container(
        padding: _padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _FoodHealthLabelColors {
  const _FoodHealthLabelColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  static const _defaultColors = _FoodHealthLabelColors(
    background: Color(0xFFEDEDED),
    foreground: Color(0xFF4A4A4A),
  );

  static _FoodHealthLabelColors forLabel(String label) {
    return switch (_normalizedKey(label)) {
      'highprotein' => const _FoodHealthLabelColors(
        background: Color(0xFFFCDCD8),
        foreground: Color(0xFF9B2825),
      ),
      'vegetarian' || 'vegan' => const _FoodHealthLabelColors(
        background: Color(0xFFD1F1EC),
        foreground: Color(0xFF087A5A),
      ),
      'lowcalorie' || 'lowcalories' => const _FoodHealthLabelColors(
        background: Color(0xFFF5F6D5),
        foreground: Color(0xFF8A4C17),
      ),
      'glutenfree' => const _FoodHealthLabelColors(
        background: Color(0xFFD6E9F8),
        foreground: Color(0xFF235C82),
      ),
      _ => _defaultColors,
    };
  }
}

String _normalizedKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          description.isEmpty ? 'Deskripsi belum tersedia.' : description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PriceComparisonSection extends StatelessWidget {
  const _PriceComparisonSection({
    required this.food,
    required this.onComparisonTap,
  });

  final FoodDetail food;
  final ValueChanged<String> onComparisonTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Comparison', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (food.priceComparisons.isEmpty)
          _EmptyPriceComparison(basePrice: food.formattedPrice)
        else
          ...food.priceComparisons.map(
            (comparison) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PriceComparisonCard(
                comparison: comparison,
                onTap: () => onComparisonTap(comparison.orderUrl),
              ),
            ),
          ),
      ],
    );
  }
}

class _FoodHeroImage extends StatelessWidget {
  const _FoodHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const _FoodImageFallback();

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _FoodImageFallback();
      },
    );
  }
}

class _FoodImageFallback extends StatelessWidget {
  const _FoodImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primaryLight.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 80, color: AppColors.primary),
      ),
    );
  }
}

class _EmptyPriceComparison extends StatelessWidget {
  const _EmptyPriceComparison({required this.basePrice});

  final String basePrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        'Harga mulai $basePrice',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.info});

  final FoodNutritionalInfo info;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _NutritionMetric(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6A21),
        value: _formatNutritionValue(info.calories),
        label: 'Kcal',
      ),
      _NutritionMetric(
        icon: Icons.circle,
        color: const Color(0xFF75A7E3),
        value: _formatNutritionValue(info.proteinG),
        label: 'Protein',
      ),
      _NutritionMetric(
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF72C34A),
        value: _formatNutritionValue(info.fatG),
        label: 'Fat',
      ),
      _NutritionMetric(
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFFFB703),
        value: _formatNutritionValue(info.carbG),
        label: 'Carb',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final isTight = constraints.maxWidth < 300;
        final spacing = isTight ? 4.0 : 8.0;

        return Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              Expanded(
                child: _NutritionMetricCard(
                  metric: metrics[i],
                  isCompact: isCompact,
                  isTight: isTight,
                ),
              ),
              if (i != metrics.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }

  static String _formatNutritionValue(double? value) {
    if (value == null) return '-';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}

class _NutritionMetric {
  const _NutritionMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
}

class _NutritionMetricCard extends StatelessWidget {
  const _NutritionMetricCard({
    required this.metric,
    required this.isCompact,
    required this.isTight,
  });

  final _NutritionMetric metric;
  final bool isCompact;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    final cardHeight = isTight ? 82.0 : (isCompact ? 90.0 : 104.0);
    final horizontalPadding = isTight ? 3.0 : (isCompact ? 4.0 : 6.0);
    final verticalPadding = isTight ? 7.0 : (isCompact ? 8.0 : 10.0);
    final iconContainerSize = isTight ? 20.0 : (isCompact ? 22.0 : 26.0);
    final iconSize = isTight ? 13.0 : (isCompact ? 15.0 : 17.0);
    final valueFontSize = isTight ? 14.0 : (isCompact ? 16.0 : 18.0);
    final labelFontSize = isTight ? 8.0 : (isCompact ? 9.0 : 10.0);
    final iconValueSpacing = isTight ? 4.0 : (isCompact ? 5.0 : 7.0);

    return Container(
      height: cardHeight,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: metric.color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.color, size: iconSize),
          ),
          SizedBox(height: iconValueSpacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.inter(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.label,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceComparisonCard extends StatelessWidget {
  const _PriceComparisonCard({required this.comparison, required this.onTap});

  final FoodPriceComparison comparison;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(comparison.platformKey);

    return Semantics(
      button: comparison.orderUrl.isNotEmpty,
      label: '${comparison.platform} price ${comparison.formattedPrice}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: comparison.orderUrl.isEmpty ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delivery_dining_rounded, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comparison.platform,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Estimasi 30-45 menit',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      comparison.formattedPrice,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (comparison.orderUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.open_in_new_rounded, size: 18, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _platformColor(String platformKey) {
    return switch (platformKey) {
      'gofood' => AppColors.goFoodColor,
      'grabfood' => AppColors.grabFoodColor,
      'shopeefood' => AppColors.shopeeFoodColor,
      _ => AppColors.primary,
    };
  }
}
