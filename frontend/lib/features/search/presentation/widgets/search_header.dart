import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchFieldColor,
    required this.hasQuery,
    required this.onBack,
    required this.onClear,
    required this.onSubmitted,
    required this.onTapOutside,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color searchFieldColor;
  final bool hasQuery;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onBack,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 29,
                color: Color(0xFF202124),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: searchFieldColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              cursorColor: const Color(0xFF202124),
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF2F3133),
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 46,
                  minHeight: 48,
                ),
                suffixIcon: hasQuery
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: const Icon(Icons.cancel_rounded),
                          color: const Color(0xFF55575A),
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          tooltip: 'Clear search',
                          onPressed: onClear,
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 48,
                ),
              ),
              onSubmitted: onSubmitted,
              onTapOutside: (_) => onTapOutside(),
            ),
          ),
        ),
      ],
    );
  }
}
