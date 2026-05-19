import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/location_item.dart';

class LocationRecentTile extends StatelessWidget {
  const LocationRecentTile({
    super.key,
    required this.location,
    required this.onTap,
  });

  final LocationItem location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      location.distanceLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: const Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 9,
                        height: 1.25,
                        color: const Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
