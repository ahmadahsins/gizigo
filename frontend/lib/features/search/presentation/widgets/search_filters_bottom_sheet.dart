import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'label_filter_bottom_sheet.dart';
import 'price_filter_bottom_sheet.dart';
import 'range_filter_bottom_sheet.dart';
import 'search_filter_bottom_sheet_shell.dart';

class SearchFilterSelection {
  SearchFilterSelection({
    required this.priceRange,
    required Set<String> selectedLabels,
    required Set<String> selectedRanges,
  }) : selectedLabels = Set.unmodifiable(selectedLabels),
       selectedRanges = Set.unmodifiable(selectedRanges);

  final RangeValues priceRange;
  final Set<String> selectedLabels;
  final Set<String> selectedRanges;

  bool get hasPriceFilter {
    return priceRange.start != PriceFilterBottomSheet.minPrice ||
        priceRange.end != PriceFilterBottomSheet.maxPrice;
  }

  bool get hasAnyFilter {
    return hasPriceFilter ||
        selectedLabels.isNotEmpty ||
        selectedRanges.isNotEmpty;
  }
}

class SearchFiltersBottomSheet extends StatefulWidget {
  const SearchFiltersBottomSheet({super.key, required this.initialSelection});

  final SearchFilterSelection initialSelection;

  @override
  State<SearchFiltersBottomSheet> createState() =>
      _SearchFiltersBottomSheetState();
}

class _SearchFiltersBottomSheetState extends State<SearchFiltersBottomSheet> {
  static const double _labelChipSpacing = 15;
  static const double _minLabelChipWidth = 88;
  static const double _maxLabelChipWidth = 105;
  static const double _rangeChipSpacing = 15;

  late RangeValues _priceRange;
  late final Set<String> _selectedLabels;
  late final Set<String> _selectedRanges;

  bool get _hasPriceFilter {
    return _priceRange.start != PriceFilterBottomSheet.minPrice ||
        _priceRange.end != PriceFilterBottomSheet.maxPrice;
  }

  bool get _hasAnyFilter {
    return _hasPriceFilter ||
        _selectedLabels.isNotEmpty ||
        _selectedRanges.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialSelection.priceRange;
    _selectedLabels = {...widget.initialSelection.selectedLabels};
    _selectedRanges = {...widget.initialSelection.selectedRanges};
  }

  @override
  Widget build(BuildContext context) {
    return SearchFilterBottomSheetShell(
      title: 'Filter',
      resetText: 'Clear',
      isResetEnabled: _hasAnyFilter,
      onReset: _clearFilters,
      onShowResults: _submitFilters,
      contentTopSpacing: 36,
      buttonTopSpacing: 42,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceSection(),
          const SizedBox(height: 34),
          _buildLabelSection(),
          const SizedBox(height: 34),
          _buildRangeSection(),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Price', style: _sectionTitleStyle),
            const Spacer(),
            TextButton(
              onPressed: _hasPriceFilter
                  ? () {
                      setState(() {
                        _priceRange = PriceFilterBottomSheet.defaultRange;
                      });
                    }
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.textHint,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              PriceFilterBottomSheet.formatRupiah(_priceRange.start),
              style: _priceValueStyle,
            ),
            Text(
              PriceFilterBottomSheet.formatRupiah(_priceRange.end),
              style: _priceValueStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: const Color(0xFFFAF7F7),
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 5,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 15,
              elevation: 2,
              pressedElevation: 4,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: PriceFilterBottomSheet.minPrice,
            max: PriceFilterBottomSheet.maxPrice,
            divisions: 1000,
            labels: RangeLabels(
              PriceFilterBottomSheet.formatRupiah(_priceRange.start),
              PriceFilterBottomSheet.formatRupiah(_priceRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = RangeValues(
                  values.start.roundToDouble(),
                  values.end.roundToDouble(),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLabelSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Label', style: _sectionTitleStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Select one or more', style: _helperTextStyle),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Tentang label gizi',
              child: Baseline(
                baseline: 11,
                baselineType: TextBaseline.alphabetic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showNutritionLabelInfoDialog(context),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF898989),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth =
                ((constraints.maxWidth - _labelChipSpacing * 2) / 3).clamp(
                  _minLabelChipWidth,
                  _maxLabelChipWidth,
                );

            return Wrap(
              spacing: _labelChipSpacing,
              runSpacing: 12,
              children: LabelFilterBottomSheet.options.map((option) {
                return _LabelFilterChip(
                  option: option,
                  width: chipWidth,
                  isSelected: _selectedLabels.contains(option.label),
                  onTap: () => _toggleSelection(_selectedLabels, option.label),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRangeSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Range', style: _sectionTitleStyle),
        const SizedBox(height: 4),
        Text('Select one or more', style: _helperTextStyle),
        const SizedBox(height: 16),
        Wrap(
          spacing: _rangeChipSpacing,
          runSpacing: 12,
          children: RangeFilterBottomSheet.ranges.map((range) {
            return _RangeFilterChip(
              label: range,
              isSelected: _selectedRanges.contains(range),
              onTap: () => _toggleSelection(_selectedRanges, range),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggleSelection(Set<String> selection, String value) {
    setState(() {
      if (selection.contains(value)) {
        selection.remove(value);
      } else {
        selection.add(value);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _priceRange = PriceFilterBottomSheet.defaultRange;
      _selectedLabels.clear();
      _selectedRanges.clear();
    });
  }

  void _submitFilters() {
    Navigator.of(context).pop(
      SearchFilterSelection(
        priceRange: _priceRange,
        selectedLabels: _selectedLabels,
        selectedRanges: _selectedRanges,
      ),
    );
  }

  TextStyle get _sectionTitleStyle {
    return AppTextStyles.heading3.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF252525),
    );
  }

  TextStyle get _helperTextStyle {
    return AppTextStyles.bodySmall.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF111111),
    );
  }

  TextStyle get _priceValueStyle {
    return AppTextStyles.bodySmall.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF111111),
    );
  }
}

class _LabelFilterChip extends StatelessWidget {
  const _LabelFilterChip({
    required this.option,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final LabelFilterOption option;
  final double width;
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
          width: width,
          height: 33,
          decoration: BoxDecoration(
            color: isSelected
                ? option.backgroundColor
                : option.backgroundColor.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: option.shadowColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(2, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? option.foregroundColor
                    : option.foregroundColor.withValues(alpha: 0.48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeFilterChip extends StatelessWidget {
  const _RangeFilterChip({
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
