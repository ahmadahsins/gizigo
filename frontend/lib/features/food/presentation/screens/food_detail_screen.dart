import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Food Detail Screen - Shows food info & price comparison from GoFood/GrabFood/ShopeeFood
class FoodDetailScreen extends StatelessWidget {
  final String foodId;

  const FoodDetailScreen({super.key, required this.foodId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with food image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                  child: Icon(
                    Icons.fastfood_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // Food info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text('Salad Bowl Premium', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),

                  // Merchant & distance
                  Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Merchant Sehat', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('1.2 km', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Health labels
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLabel('High Protein'),
                      _buildLabel('Low Calorie'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('Deskripsi', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(
                    'Salad bowl premium dengan campuran sayuran segar, protein tinggi, dan dressing spesial. Cocok untuk kamu yang ingin makan sehat tanpa ribet!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price comparison section
                  Text('Bandingkan Harga 💰', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),

                  // GoFood
                  _buildPriceCard(
                    'GoFood',
                    'Rp 25.000',
                    AppColors.goFoodColor,
                    Icons.delivery_dining_rounded,
                  ),
                  const SizedBox(height: 10),

                  // GrabFood
                  _buildPriceCard(
                    'GrabFood',
                    'Rp 23.500',
                    AppColors.grabFoodColor,
                    Icons.delivery_dining_rounded,
                  ),
                  const SizedBox(height: 10),

                  // ShopeeFood
                  _buildPriceCard(
                    'ShopeeFood',
                    'Rp 22.000',
                    AppColors.shopeeFoodColor,
                    Icons.delivery_dining_rounded,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    String service,
    String price,
    Color color,
    IconData icon,
  ) {
    return Container(
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: GoogleFonts.plusJakartaSans(
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
          Text(
            price,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.open_in_new_rounded, size: 18, color: color),
        ],
      ),
    );
  }
}
