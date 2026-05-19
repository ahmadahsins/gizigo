import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import 'search_filter_bottom_sheet_shell.dart';

class LabelFilterBottomSheet extends StatefulWidget {
  const LabelFilterBottomSheet({
    super.key,
    required this.initialSelectedLabels,
  });

  static const List<LabelFilterOption> options = [
    LabelFilterOption(
      label: 'Good',
      backgroundColor: Color(0xFFD3FCDC),
      foregroundColor: Color(0xFF196B2B),
      shadowColor: Color(0xFFBDE9C6),
    ),
    LabelFilterOption(
      label: 'Very good',
      backgroundColor: Color(0xFF156F24),
      foregroundColor: Colors.white,
      shadowColor: Color(0xFF0B3514),
    ),
    LabelFilterOption(
      label: 'Excellent',
      backgroundColor: Color(0xFFF45A00),
      foregroundColor: Colors.white,
      shadowColor: Color(0xFF783006),
    ),
  ];

  final Set<String> initialSelectedLabels;

  @override
  State<LabelFilterBottomSheet> createState() => _LabelFilterBottomSheetState();
}

class _LabelFilterBottomSheetState extends State<LabelFilterBottomSheet> {
  static const double _chipSpacing = 15;
  static const double _minChipWidth = 88;
  static const double _maxChipWidth = 105;

  late final Set<String> _selectedLabels;

  @override
  void initState() {
    super.initState();
    _selectedLabels = {...widget.initialSelectedLabels};
  }

  @override
  Widget build(BuildContext context) {
    return SearchFilterBottomSheetShell(
      title: 'Label',
      isResetEnabled: _selectedLabels.isNotEmpty,
      onReset: () => setState(_selectedLabels.clear),
      onShowResults: () => Navigator.of(context).pop({..._selectedLabels}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select one or more',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF242424),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Tentang label gizi',
                child: Baseline(
                  baseline: 15,
                  baselineType: TextBaseline.alphabetic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showNutritionLabelInfo,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
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
              final chipWidth = ((constraints.maxWidth - _chipSpacing * 2) / 3)
                  .clamp(_minChipWidth, _maxChipWidth);

              return Wrap(
                spacing: _chipSpacing,
                runSpacing: 12,
                children: LabelFilterBottomSheet.options.map((option) {
                  return _LabelChoiceChip(
                    option: option,
                    width: chipWidth,
                    isSelected: _selectedLabels.contains(option.label),
                    onTap: () => _toggleLabel(option.label),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleLabel(String label) {
    setState(() {
      if (_selectedLabels.contains(label)) {
        _selectedLabels.remove(label);
      } else {
        _selectedLabels.add(label);
      }
    });
  }

  Future<void> _showNutritionLabelInfo() {
    return showNutritionLabelInfoDialog(context);
  }
}

Future<void> showNutritionLabelInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      return const _NutritionLabelInfoDialog();
    },
  );
}

class _NutritionLabelInfoDialog extends StatelessWidget {
  const _NutritionLabelInfoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: const Color(0xFFFAF7F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tentang Label Gizi',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Label pada makanan membantu kamu memahami kualitas nutrisi dari menu yang dipilih. Semakin tinggi labelnya, semakin baik dan seimbang kandungan gizinya untuk tubuh.',
                style: _dialogBodyStyle,
              ),
              const SizedBox(height: 18),
              const _LabelInfoLine(
                label: 'Good',
                description: 'Cukup baik untuk konsumsi sehari-hari',
              ),
              const SizedBox(height: 6),
              const _LabelInfoLine(
                label: 'Very Good',
                description: 'Nutrisi lebih seimbang dan lebih sehat',
              ),
              const SizedBox(height: 6),
              const _LabelInfoLine(
                label: 'Excellent',
                description:
                    'Pilihan terbaik dengan kandungan gizi paling baik',
              ),
              const SizedBox(height: 18),
              Text(
                'Note: Gunakan label ini sebagai panduan untuk memilih makanan yang lebih sesuai dengan kebutuhanmu.',
                style: _dialogBodyStyle,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextStyle get _dialogBodyStyle {
    return AppTextStyles.bodySmall.copyWith(
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF333333),
    );
  }
}

class _LabelInfoLine extends StatelessWidget {
  const _LabelInfoLine({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = _NutritionLabelInfoDialog._dialogBodyStyle;

    return RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(
            text: '$label: ',
            style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: description),
        ],
      ),
    );
  }
}

class _LabelChoiceChip extends StatelessWidget {
  const _LabelChoiceChip({
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

class LabelFilterOption {
  const LabelFilterOption({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.shadowColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
}
