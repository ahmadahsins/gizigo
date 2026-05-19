import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'rating_badge.dart';

class RecommendationCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String price;
  final String ratingText;
  final VoidCallback? onTap;
  final double imageSize;
  final double imageBorderRadius;
  final EdgeInsetsGeometry margin;
  final double priceFontSize;
  final bool compactMetaRow;

  const RecommendationCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.ratingText,
    this.onTap,
    this.imageSize = 88,
    this.imageBorderRadius = 16,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.priceFontSize = 14,
    this.compactMetaRow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        color: Colors.transparent,
        child: Row(
          children: [
            // Image
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(imageBorderRadius),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageBorderRadius),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: compactMetaRow
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      RatingBadge(text: ratingText),
                      if (compactMetaRow) const SizedBox(width: 10),
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: priceFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
