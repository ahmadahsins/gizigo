import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Profile Screen - User profile & settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // User name
              Text('Mahasiswa GiziGo', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text('user@email.com', style: AppTextStyles.bodySmall),
              const SizedBox(height: 32),

              // Menu items
              _buildMenuItem(
                Icons.favorite_outline_rounded,
                'Makanan Favorit',
                () {},
              ),
              _buildMenuItem(
                Icons.history_rounded,
                'Riwayat Pencarian',
                () {},
              ),
              _buildMenuItem(
                Icons.settings_outlined,
                'Pengaturan',
                () {},
              ),
              _buildMenuItem(
                Icons.help_outline_rounded,
                'Bantuan',
                () {},
              ),
              _buildMenuItem(
                Icons.info_outline_rounded,
                'Tentang GiziGo',
                () {},
              ),
              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement logout
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    'Keluar',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
