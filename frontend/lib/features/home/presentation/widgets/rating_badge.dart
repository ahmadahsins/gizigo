import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/nutrition_grade.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final grade = NutritionGrade.tryParse(text);
    final displayText = NutritionGrade.labelFor(text);
    final colors = _colorsFor(grade);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );

    if (onTap == null) return badge;

    return Semantics(
      button: true,
      label: '$displayText nutrition rating. Tap for details.',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: badge,
          ),
        ),
      ),
    );
  }

  _RatingBadgeColors _colorsFor(NutritionGrade? grade) {
    return switch (grade) {
      NutritionGrade.good => const _RatingBadgeColors(
        background: Color(0xFFD3F9D8),
        foreground: Color(0xFF1B6D24),
      ),
      NutritionGrade.veryGood => const _RatingBadgeColors(
        background: Color(0xFF1B6D24),
        foreground: Colors.white,
      ),
      NutritionGrade.excellent => const _RatingBadgeColors(
        background: Color(0xFFE65100),
        foreground: Colors.white,
      ),
      null => const _RatingBadgeColors(
        background: Color(0xFF6C757D),
        foreground: Colors.white,
      ),
    };
  }
}

class _RatingBadgeColors {
  const _RatingBadgeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
