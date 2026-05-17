import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Search Screen - Search food by name/description
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cari Makanan', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  // Search input
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ketik nama makanan...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          // TODO: Show filter bottom sheet
                        },
                      ),
                    ),
                    onChanged: (query) {
                      // TODO: Implement search with debounce
                    },
                  ),
                ],
              ),
            ),

            // Search results area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 80,
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cari makanan sehat favoritmu',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
