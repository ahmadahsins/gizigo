import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'search_filter_bottom_sheet_shell.dart';

class PriceFilterBottomSheet extends StatefulWidget {
  const PriceFilterBottomSheet({super.key, required this.initialRange});

  static const double minPrice = 0;
  static const double maxPrice = 1000000;
  static const RangeValues defaultRange = RangeValues(minPrice, maxPrice);

  final RangeValues initialRange;

  static String formatRupiah(double value) {
    final roundedValue = value.round();
    final formattedValue = roundedValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$formattedValue';
  }

  @override
  State<PriceFilterBottomSheet> createState() => _PriceFilterBottomSheetState();
}

class _PriceFilterBottomSheetState extends State<PriceFilterBottomSheet> {
  late RangeValues _selectedRange;

  bool get _hasCustomRange {
    return _selectedRange.start != PriceFilterBottomSheet.minPrice ||
        _selectedRange.end != PriceFilterBottomSheet.maxPrice;
  }

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    return SearchFilterBottomSheetShell(
      title: 'Price',
      isResetEnabled: _hasCustomRange,
      onReset: () {
        setState(() => _selectedRange = PriceFilterBottomSheet.defaultRange);
      },
      onShowResults: () => Navigator.of(context).pop(_selectedRange),
      buttonTopSpacing: 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PriceFilterBottomSheet.formatRupiah(_selectedRange.start),
                style: _valueStyle,
              ),
              Text(
                PriceFilterBottomSheet.formatRupiah(_selectedRange.end),
                style: _valueStyle,
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
              values: _selectedRange,
              min: PriceFilterBottomSheet.minPrice,
              max: PriceFilterBottomSheet.maxPrice,
              divisions: 1000,
              labels: RangeLabels(
                PriceFilterBottomSheet.formatRupiah(_selectedRange.start),
                PriceFilterBottomSheet.formatRupiah(_selectedRange.end),
              ),
              onChanged: (values) {
                setState(() {
                  _selectedRange = RangeValues(
                    values.start.roundToDouble(),
                    values.end.roundToDouble(),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _valueStyle {
    return AppTextStyles.bodyLarge.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF111111),
    );
  }
}
