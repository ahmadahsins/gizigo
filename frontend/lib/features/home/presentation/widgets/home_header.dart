import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_router.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.locationName,
    required this.onLocationTap,
  });

  final String locationName;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, GiziGang 👋',
                style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                button: true,
                label: 'Change location',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLocationTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            onTap: () => context.pushNamed(AppRouter.profile),
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}
