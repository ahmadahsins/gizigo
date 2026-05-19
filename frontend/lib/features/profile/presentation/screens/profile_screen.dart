import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/presentation/widgets/custom_search_bar.dart';
import '../../../home/presentation/widgets/recommendation_card.dart';

enum _ProfileView { menu, account, history }

/// Profile Screen - User profile & settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const double _horizontalPadding = 24;
  static const Color _tileColor = Color(0xFFF2EEEE);
  static const Color _fieldColor = Color(0xFFF3F0F0);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _genderController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  _ProfileView _view = _ProfileView.menu;
  bool _isEditingAccount = false;

  String _savedFullName = 'GiziGang';
  String _savedEmail = 'gizigang@gmail.com';
  String _savedGender = 'Female';
  String _savedAge = '19';
  String _savedHeight = '160';
  String _savedWeight = '50';

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: _savedFullName);
    _emailController = TextEditingController(text: _savedEmail);
    _genderController = TextEditingController(text: _savedGender);
    _ageController = TextEditingController(text: _savedAge);
    _heightController = TextEditingController(text: _savedHeight);
    _weightController = TextEditingController(text: _savedWeight);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _view == _ProfileView.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _view != _ProfileView.menu) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ProfileScreen._horizontalPadding,
                  21,
                  ProfileScreen._horizontalPadding,
                  40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 61,
                  ),
                  child: IntrinsicHeight(
                    child: switch (_view) {
                      _ProfileView.account => _AccountContent(
                        isEditing: _isEditingAccount,
                        fullNameController: _fullNameController,
                        emailController: _emailController,
                        genderController: _genderController,
                        ageController: _ageController,
                        heightController: _heightController,
                        weightController: _weightController,
                        onBack: _handleBack,
                        onEdit: _enableAccountEditing,
                        onEditPhoto: _handleEditPhoto,
                        onSave: _saveAccountChanges,
                        onDiscard: _discardAccountChanges,
                        onGenderChanged: _setGender,
                      ),
                      _ProfileView.history => _HistoryContent(
                        onBack: _handleBack,
                      ),
                      _ProfileView.menu => _ProfileMenuContent(
                        displayName: _savedFullName,
                        onBack: _handleBack,
                        onAccountTap: _openAccount,
                        onHistoryTap: _openHistory,
                      ),
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (_view == _ProfileView.account) {
      _discardAccountChanges();
      setState(() => _view = _ProfileView.menu);
      return;
    }

    if (_view == _ProfileView.history) {
      setState(() => _view = _ProfileView.menu);
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/');
  }

  void _openAccount() {
    setState(() => _view = _ProfileView.account);
  }

  void _openHistory() {
    setState(() => _view = _ProfileView.history);
  }

  void _enableAccountEditing() {
    setState(() => _isEditingAccount = true);
  }

  void _handleEditPhoto() {
    // TODO: Connect to image picker when profile photo persistence is ready.
  }

  void _setGender(String? gender) {
    if (gender == null) return;

    setState(() => _genderController.text = gender);
  }

  void _saveAccountChanges() {
    setState(() {
      _savedFullName = _fullNameController.text.trim();
      _savedEmail = _emailController.text.trim();
      _savedGender = _genderController.text.trim();
      _savedAge = _ageController.text.trim();
      _savedHeight = _heightController.text.trim();
      _savedWeight = _weightController.text.trim();
      _isEditingAccount = false;
    });
  }

  void _discardAccountChanges() {
    _fullNameController.text = _savedFullName;
    _emailController.text = _savedEmail;
    _genderController.text = _savedGender;
    _ageController.text = _savedAge;
    _heightController.text = _savedHeight;
    _weightController.text = _savedWeight;

    if (_isEditingAccount) {
      setState(() => _isEditingAccount = false);
    }
  }
}

class _ProfileMenuContent extends StatelessWidget {
  const _ProfileMenuContent({
    required this.displayName,
    required this.onBack,
    required this.onAccountTap,
    required this.onHistoryTap,
  });

  final String displayName;
  final VoidCallback onBack;
  final VoidCallback onAccountTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onPressed: onBack),
        const SizedBox(height: 22),
        const Center(child: _ProfileAvatar()),
        const SizedBox(height: 17),
        Center(
          child: Text(
            displayName,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
              color: const Color(0xFF242424),
            ),
          ),
        ),
        const SizedBox(height: 48),
        const _SectionTitle('Settings'),
        const SizedBox(height: 11),
        _ProfileMenuTile(
          icon: Icons.person_outline_rounded,
          label: 'Account',
          onTap: onAccountTap,
        ),
        const SizedBox(height: 7),
        _ProfileMenuTile(
          icon: Icons.restaurant_outlined,
          label: 'Food Preference',
          onTap: () {},
        ),
        const SizedBox(height: 7),
        _ProfileMenuTile(
          icon: Icons.history_rounded,
          label: 'History',
          onTap: onHistoryTap,
        ),
        const SizedBox(height: 7),
        _ProfileMenuTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          onTap: () {},
        ),
        const SizedBox(height: 37),
        const _SectionTitle('App References'),
        const SizedBox(height: 11),
        _ProfileMenuTile(
          icon: Icons.language_rounded,
          label: 'Language',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'English (US)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF242424),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 25,
                color: Color(0xFF242424),
              ),
            ],
          ),
          onTap: () {},
        ),
      ],
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.onBack});

  static const String _foodImageUrl =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=240&q=80';

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackButton(onPressed: onBack),
            const SizedBox(width: 25),
            Text(
              'Recently viewed',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1,
                color: const Color(0xFF242424),
              ),
            ),
          ],
        ),
        const SizedBox(height: 21),
        const CustomSearchBar(),
        const SizedBox(height: 24),
        const _HistorySection(
          title: 'Today',
          items: [
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp16.000',
              ratingText: 'Excellent',
              imageUrl: _foodImageUrl,
            ),
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp14.000',
              ratingText: 'Very good',
              imageUrl: _foodImageUrl,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _HistorySection(
          title: 'Yesterday',
          items: [
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp15.500',
              ratingText: 'Excellent',
              imageUrl: _foodImageUrl,
            ),
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp16.000',
              ratingText: 'Good',
              imageUrl: _foodImageUrl,
            ),
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp14.000',
              ratingText: 'Very good',
              imageUrl: _foodImageUrl,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _HistorySection(
          title: '9 May 2026',
          items: [
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp15.500',
              ratingText: 'Excellent',
              imageUrl: _foodImageUrl,
            ),
            _HistoryFoodItem(
              title: 'Lorem ipsum',
              subtitle: 'Lorem ipsum',
              price: 'Rp14.000',
              ratingText: 'Good',
              imageUrl: _foodImageUrl,
            ),
          ],
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.items});

  final String title;
  final List<_HistoryFoodItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4A4A4A),
            height: 1,
          ),
        ),
        const SizedBox(height: 17),
        ...items.map(
          (item) => RecommendationCard(
            imageUrl: item.imageUrl,
            title: item.title,
            subtitle: item.subtitle,
            price: item.price,
            ratingText: item.ratingText,
          ),
        ),
      ],
    );
  }
}

class _HistoryFoodItem {
  const _HistoryFoodItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.ratingText,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String price;
  final String ratingText;
  final String imageUrl;
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.isEditing,
    required this.fullNameController,
    required this.emailController,
    required this.genderController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.onBack,
    required this.onEdit,
    required this.onEditPhoto,
    required this.onSave,
    required this.onDiscard,
    required this.onGenderChanged,
  });

  final bool isEditing;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController genderController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onEditPhoto;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final ValueChanged<String?> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onPressed: onBack),
        const SizedBox(height: 22),
        Center(
          child: _ProfileAvatar(
            size: 124,
            showEditButton: isEditing,
            onEditPhoto: onEditPhoto,
          ),
        ),
        const SizedBox(height: 63),
        _AccountField(
          label: 'Full Name',
          controller: fullNameController,
          enabled: isEditing,
        ),
        const SizedBox(height: 22),
        _AccountField(
          label: 'Email',
          controller: emailController,
          enabled: isEditing,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _AccountGenderField(
                controller: genderController,
                enabled: isEditing,
                onChanged: onGenderChanged,
              ),
            ),
            const SizedBox(width: 19),
            Expanded(
              child: _AccountField(
                label: 'Age',
                controller: ageController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _AccountField(
                label: 'Height',
                controller: heightController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                suffixText: 'cm',
              ),
            ),
            const SizedBox(width: 19),
            Expanded(
              child: _AccountField(
                label: 'Weight',
                controller: weightController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(height: 36),
        if (isEditing) ...[
          _PrimaryProfileButton(text: 'Save Changes', onPressed: onSave),
          const SizedBox(height: 18),
          _SecondaryProfileButton(
            text: 'Discard Changes',
            onPressed: onDiscard,
          ),
        ] else
          _PrimaryProfileButton(text: 'Edit', onPressed: onEdit),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.size = 108,
    this.showEditButton = false,
    this.onEditPhoto,
  });

  final double size;
  final bool showEditButton;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: size * 0.15,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.16,
            child: ClipOval(
              child: Container(
                width: size * 0.67,
                height: size * 0.35,
                color: Colors.white,
              ),
            ),
          ),
          if (showEditButton)
            Positioned(
              right: 1,
              bottom: 5,
              child: Material(
                color: const Color(0xFF242424),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEditPhoto,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 31,
                    height: 31,
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountGenderField extends StatelessWidget {
  const _AccountGenderField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _AccountField(
        label: 'Gender',
        controller: controller,
        enabled: false,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF242424),
            height: 1,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 49,
          child: DropdownButtonFormField<String>(
            initialValue: controller.text.isEmpty ? null : controller.text,
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(7),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6E6E6E),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6E6E),
              height: 1,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: ProfileScreen._fieldColor,
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(color: AppColors.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            items: const ['Male', 'Female']
                .map(
                  (gender) => DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder({Color color = const Color(0xFFC9C4C4)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color),
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.suffixText,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF242424),
            height: 1,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 49,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6E6E),
              height: 1,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: ProfileScreen._fieldColor,
              disabledBorder: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(color: AppColors.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              suffixIcon: suffixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          suffixText!,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF242424),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder({Color color = const Color(0xFFC9C4C4)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color),
    );
  }
}

class _PrimaryProfileButton extends StatelessWidget {
  const _PrimaryProfileButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(46),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(
          text,
          style: AppTextStyles.button.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SecondaryProfileButton extends StatelessWidget {
  const _SecondaryProfileButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: ProfileScreen._fieldColor,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(46),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(
          text,
          style: AppTextStyles.button.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF333333),
        height: 1.1,
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileScreen._tileColor,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: const Color(0xFF242424)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1,
                      color: const Color(0xFF242424),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
