import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FoodPreferenceContent extends StatefulWidget {
  const FoodPreferenceContent({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<FoodPreferenceContent> createState() => _FoodPreferenceContentState();
}

class _FoodPreferenceContentState extends State<FoodPreferenceContent> {
  static const Color _textColor = Color(0xFF242424);
  static const Color _bodyColor = Color(0xFF5F5F5F);
  static const Color _chipFillColor = Color(0xFFF1EEEE);
  static const Color _chipBorderColor = Color(0xFFC9C4C4);
  static const Color _selectedColor = AppColors.primary;
  static const double _contentMaxWidth = 372;

  static const List<_PreferenceChipData> _userGoals = [
    _PreferenceChipData(icon: Icons.south_east_rounded, label: 'Lose Weight'),
    _PreferenceChipData(
      icon: Icons.eco_outlined,
      label: 'Vegetarian Lifestyle',
    ),
    _PreferenceChipData(
      icon: Icons.fitness_center_rounded,
      label: 'Gain Muscle',
    ),
    _PreferenceChipData(icon: Icons.balance_rounded, label: 'Maintain Weight'),
    _PreferenceChipData(
      icon: Icons.local_fire_department_rounded,
      label: 'Eat Healthier',
    ),
  ];

  static const List<_PreferenceChipData> _dietaryRestrictions = [
    _PreferenceChipData(
      icon: Icons.set_meal_outlined,
      label: 'Seafood Allergy',
    ),
    _PreferenceChipData(
      icon: Icons.water_drop_rounded,
      label: 'Lactose Intolerant',
    ),
    _PreferenceChipData(icon: Icons.egg_outlined, label: 'Egg Allergy'),
    _PreferenceChipData(icon: Icons.more_horiz_rounded, label: 'Others'),
  ];

  static const List<_TasteProfileData> _tasteProfiles = [
    _TasteProfileData(
      title: 'Traditional Indonesian Food',
      description:
          'Classic local dishes with authentic Indonesian flavors and spices.',
      imageAsset: 'assets/images/food_preference_traditional.png',
    ),
    _TasteProfileData(
      title: 'Fusion Food',
      description:
          'A mix of Indonesian and international cuisine with a modern twist.',
      imageAsset: 'assets/images/food_preference_fusion.png',
    ),
    _TasteProfileData(
      title: 'Western Food',
      description:
          'Popular western-style meals that are light, creamy, or savory.',
      imageAsset: 'assets/images/food_preference_western.png',
    ),
  ];

  final Set<String> _selectedGoals = {};
  final Set<String> _selectedRestrictions = {};
  final Set<String> _selectedTasteProfiles = {};
  bool _isSaved = false;

  List<_PreferenceChipData> get _selectedGoalItems {
    return _userGoals
        .where((item) => _selectedGoals.contains(item.label))
        .toList(growable: false);
  }

  List<_PreferenceChipData> get _selectedRestrictionItems {
    return _dietaryRestrictions
        .where((item) => _selectedRestrictions.contains(item.label))
        .toList(growable: false);
  }

  List<_TasteProfileData> get _visibleTasteProfiles {
    if (!_isSaved) return _tasteProfiles;

    return _tasteProfiles
        .where((item) => _selectedTasteProfiles.contains(item.title))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FoodPreferenceBackButton(onPressed: widget.onBack),
                const SizedBox(width: 25),
                Expanded(
                  child: Text(
                    'Food Preference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: _textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Text(
              'Help GiziGo understand your eating preferences\n'
              'to discover meals that are safer, healthier, and\n'
              'more suited to your taste.',
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 16,
                height: 1.35,
                color: _bodyColor,
              ),
            ),
            const SizedBox(height: 39),
            _FoodPreferenceSectionHeader(
              title: 'User Goals',
              helperText: _isSaved ? null : 'Select one or more',
            ),
            const SizedBox(height: 17),
            if (_isSaved)
              _PreferenceSummary(
                items: _selectedGoalItems,
                emptyMessage: 'No goals selected.',
              )
            else
              _PreferenceChipWrap(
                items: _userGoals,
                selectedLabels: _selectedGoals,
                isInteractionEnabled: true,
                onTap: (item) => _toggleSelection(_selectedGoals, item.label),
              ),
            const SizedBox(height: 38),
            _FoodPreferenceSectionHeader(
              title: 'Dietary Restriction &\nAllergies',
              helperText: _isSaved ? null : 'Optional',
            ),
            const SizedBox(height: 17),
            if (_isSaved)
              _PreferenceSummary(
                items: _selectedRestrictionItems,
                emptyMessage: 'No dietary restrictions selected.',
              )
            else
              _PreferenceChipWrap(
                items: _dietaryRestrictions,
                selectedLabels: _selectedRestrictions,
                isInteractionEnabled: true,
                onTap: (item) =>
                    _toggleSelection(_selectedRestrictions, item.label),
              ),
            const SizedBox(height: 37),
            _FoodPreferenceSectionHeader(
              title: 'Taste Profile',
              helperText: _isSaved ? null : 'Select one or more',
            ),
            const SizedBox(height: 20),
            ..._visibleTasteProfiles.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _TasteProfileCard(
                  profile: profile,
                  isSelected: _selectedTasteProfiles.contains(profile.title),
                  isInteractionEnabled: !_isSaved,
                  onTap: () =>
                      _toggleSelection(_selectedTasteProfiles, profile.title),
                ),
              ),
            ),
            SizedBox(height: _isSaved ? 27 : 29),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _isSaved ? _editPreference : _savePreference,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.26),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  _isSaved ? 'Edit Preference' : 'Save Preference',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 27),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(Set<String> selectedItems, String value) {
    setState(() {
      if (!selectedItems.add(value)) {
        selectedItems.remove(value);
      }
    });
  }

  void _savePreference() {
    if (_selectedTasteProfiles.isEmpty) {
      _showSnackBar('Pilih minimal satu taste profile dulu.');
      return;
    }

    setState(() => _isSaved = true);
    _showSnackBar('Preference saved locally.');
  }

  void _editPreference() {
    setState(() => _isSaved = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PreferenceChipData {
  const _PreferenceChipData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({required this.items, required this.emptyMessage});

  final List<_PreferenceChipData> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _PreferenceEmptyState(message: emptyMessage);
    }

    return _PreferenceChipWrap(
      items: items,
      selectedLabels: items.map((item) => item.label).toSet(),
      isInteractionEnabled: false,
      onTap: (_) {},
    );
  }
}

class _PreferenceEmptyState extends StatelessWidget {
  const _PreferenceEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 39),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1DDDD)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: const Color(0xFF777272),
        ),
      ),
    );
  }
}

class _TasteProfileData {
  const _TasteProfileData({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String title;
  final String description;
  final String imageAsset;
}

class _FoodPreferenceBackButton extends StatelessWidget {
  const _FoodPreferenceBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 31,
      height: 31,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded),
        iconSize: 30,
        color: const Color(0xFF242424),
        splashRadius: 24,
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        tooltip: 'Back',
      ),
    );
  }
}

class _FoodPreferenceSectionHeader extends StatelessWidget {
  const _FoodPreferenceSectionHeader({required this.title, this.helperText});

  final String title;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: const Color(0xFF242424),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              helperText!,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                height: 1,
                color: const Color(0xFF777272),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreferenceChipWrap extends StatelessWidget {
  const _PreferenceChipWrap({
    required this.items,
    required this.selectedLabels,
    required this.isInteractionEnabled,
    required this.onTap,
  });

  final List<_PreferenceChipData> items;
  final Set<String> selectedLabels;
  final bool isInteractionEnabled;
  final ValueChanged<_PreferenceChipData> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipWidth = (constraints.maxWidth - 18) / 2;

        return Wrap(
          spacing: 18,
          runSpacing: 14,
          children: items
              .map(
                (item) => _PreferenceChip(
                  item: item,
                  width: chipWidth,
                  isSelected: selectedLabels.contains(item.label),
                  isInteractionEnabled: isInteractionEnabled,
                  onTap: () => onTap(item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({
    required this.item,
    required this.width,
    required this.isSelected,
    required this.isInteractionEnabled,
    required this.onTap,
  });

  final _PreferenceChipData item;
  final double width;
  final bool isSelected;
  final bool isInteractionEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? _FoodPreferenceContentState._selectedColor
        : const Color(0xFF565353);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractionEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: width,
          height: 39,
          decoration: BoxDecoration(
            color: _FoodPreferenceContentState._chipFillColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _FoodPreferenceContentState._selectedColor
                  : _FoodPreferenceContentState._chipBorderColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                Icon(item.icon, size: 16, color: foregroundColor),
                const SizedBox(width: 9),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: foregroundColor,
                      ),
                    ),
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

class _TasteProfileCard extends StatelessWidget {
  const _TasteProfileCard({
    required this.profile,
    required this.isSelected,
    required this.isInteractionEnabled,
    required this.onTap,
  });

  final _TasteProfileData profile;
  final bool isSelected;
  final bool isInteractionEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F7),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: isInteractionEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.asset(
                            profile.imageAsset,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (isSelected)
                            Positioned(
                              right: 18,
                              top: 18,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox(
                                  width: 39,
                                  height: 39,
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(17, 12, 17, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: const Color(0xFF242424),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 13,
                                height: 1.35,
                                color: const Color(0xFF464242),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: _FoodPreferenceContentState._selectedColor,
                            width: 2,
                          ),
                        ),
                      ),
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
