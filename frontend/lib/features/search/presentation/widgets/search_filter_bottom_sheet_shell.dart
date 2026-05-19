import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SearchFilterBottomSheetShell extends StatelessWidget {
  const SearchFilterBottomSheetShell({
    super.key,
    required this.title,
    required this.isResetEnabled,
    required this.onReset,
    required this.onShowResults,
    required this.child,
    this.resetText = 'Reset',
    this.contentTopSpacing = 32,
    this.buttonTopSpacing = 42,
  });

  final String title;
  final bool isResetEnabled;
  final VoidCallback onReset;
  final VoidCallback onShowResults;
  final Widget child;
  final String resetText;
  final double contentTopSpacing;
  final double buttonTopSpacing;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Material(
      color: const Color(0xFFFAF7F7),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 28,
                      color: const Color(0xFF1F1F1F),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 30,
                        height: 30,
                      ),
                      tooltip: 'Close',
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF252525),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isResetEnabled ? onReset : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF252525),
                        disabledForegroundColor: AppColors.textHint,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(46, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(resetText),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE4E0E0)),
                SizedBox(height: contentTopSpacing),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: SizedBox(width: double.infinity, child: child),
                  ),
                ),
                SizedBox(height: buttonTopSpacing),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onShowResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: AppTextStyles.button.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Show Results'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
