import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class SearchSectionTitle extends StatelessWidget {
  const SearchSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.heading3.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: const Color(0xFF202124),
      ),
    );
  }
}
