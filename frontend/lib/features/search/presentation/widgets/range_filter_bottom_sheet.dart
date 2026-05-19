import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import 'search_filter_bottom_sheet_shell.dart';

class RangeFilterBottomSheet extends StatefulWidget {
  const RangeFilterBottomSheet({
    super.key,
    required this.initialSelectedRanges,
  });

  static const String lessThanTwoKm = '< 2 km';
  static const String twoToFiveKm = '2 - 5 km';
  static const String moreThanFiveKm = '> 5 km';
  static const List<String> ranges = [
    lessThanTwoKm,
    twoToFiveKm,
    moreThanFiveKm,
  ];

  final Set<String> initialSelectedRanges;

  @override
  State<RangeFilterBottomSheet> createState() => _RangeFilterBottomSheetState();
}

class _RangeFilterBottomSheetState extends State<RangeFilterBottomSheet> {
  static const double _chipSpacing = 15;

  late final Set<String> _selectedRanges;

  @override
  void initState() {
    super.initState();
    _selectedRanges = {...widget.initialSelectedRanges};
  }

  @override
  Widget build(BuildContext context) {
    return SearchFilterBottomSheetShell(
      title: 'Range',
      isResetEnabled: _selectedRanges.isNotEmpty,
      onReset: () => setState(_selectedRanges.clear),
      onShowResults: () => Navigator.of(context).pop({..._selectedRanges}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select one or more',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF242424),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: _chipSpacing,
            runSpacing: 12,
            children: RangeFilterBottomSheet.ranges.map((range) {
              return _RangeChoiceChip(
                label: range,
                isSelected: _selectedRanges.contains(range),
                onTap: () => _toggleRange(range),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleRange(String range) {
    setState(() {
      if (_selectedRanges.contains(range)) {
        _selectedRanges.remove(range);
      } else {
        _selectedRanges.add(range);
      }
    });
  }
}

class _RangeChoiceChip extends StatelessWidget {
  const _RangeChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 78,
          height: 33,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F4EA) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B6D24)
                  : const Color(0xFFE2E2E2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF1B6D24)
                    : const Color(0xFF222222),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
