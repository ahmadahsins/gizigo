import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterDropdownChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const FilterDropdownChip({
    super.key,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F4EA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1B6D24) : const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF1B6D24)
                    : const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isActive
                  ? const Color(0xFF1B6D24)
                  : const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}
