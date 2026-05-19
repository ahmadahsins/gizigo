import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingBadge extends StatelessWidget {
  final String text;

  const RatingBadge({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (text.toLowerCase()) {
      case 'excellent':
        bgColor = const Color(0xFFE65100);
        break;
      case 'very good':
        bgColor = const Color(0xFF1B6D24);
        break;
      case 'good':
        bgColor = const Color(0xFFD3F9D8);
        textColor = const Color(0xFF1B6D24);
        break;
      default:
        bgColor = const Color(0xFF6C757D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
