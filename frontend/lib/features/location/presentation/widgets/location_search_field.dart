import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class LocationSearchField extends StatelessWidget {
  const LocationSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onTapOutside,
    this.hasText = false,
    this.onClear,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: const Color(0xFF202124),
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF202124),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Search location',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF666666),
          ),
          contentPadding: EdgeInsets.zero,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 18, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF202124),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 52,
            minHeight: 44,
          ),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Clear location search',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF202124),
                    size: 20,
                  ),
                  onPressed: onClear,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 44,
          ),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => onTapOutside(),
      ),
    );
  }
}
