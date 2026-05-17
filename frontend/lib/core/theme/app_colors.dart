import 'package:flutter/material.dart';

/// GiziGo App Color Palette
class AppColors {
  AppColors._();

  // Primary - Fresh Green (represents healthy food)
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryLight = Color(0xFF6FE89D);
  static const Color primaryDark = Color(0xFF1A9B50);

  // Secondary - Warm Orange (represents appetite/energy)
  static const Color secondary = Color(0xFFFF8C42);
  static const Color secondaryLight = Color(0xFFFFB074);
  static const Color secondaryDark = Color(0xFFE06B1F);

  // Accent
  static const Color accent = Color(0xFFFFC107);

  // Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);

  // Status
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Delivery Service Colors
  static const Color goFoodColor = Color(0xFF00880F);
  static const Color grabFoodColor = Color(0xFF00B14F);
  static const Color shopeeFoodColor = Color(0xFFEE4D2D);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
