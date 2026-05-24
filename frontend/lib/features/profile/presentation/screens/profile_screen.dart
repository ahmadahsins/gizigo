import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/auto_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../router/app_router.dart';
import '../../data/models/profile_history_item.dart';
import '../../data/models/profile_user.dart';
import '../../data/profile_remote_data_source.dart';
import '../widgets/food_preference_content.dart';
import '../../../home/presentation/widgets/custom_search_bar.dart';
import '../../../home/presentation/widgets/recommendation_card.dart';

enum _ProfileView { menu, account, foodPreference, history }

/// Profile Screen - User profile & settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const double _horizontalPadding = 24;
  static const Color _tileColor = Color(0xFFF2EEEE);
  static const Color _fieldColor = Color(0xFFF3F0F0);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutoRefreshStateMixin<ProfileScreen> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _genderController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final ProfileRemoteDataSource _profileRemoteDataSource;
  late final ImagePicker _imagePicker;

  _ProfileView _view = _ProfileView.menu;
  bool _isEditingAccount = false;
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isUploadingPhoto = false;
  bool _isLoadingHistory = false;

  String _savedFullName = '';
  String _savedEmail = '';
  String _savedGender = '';
  String _savedAge = '';
  String _savedHeight = '';
  String _savedWeight = '';
  String _savedProfilePhotoUrl = '';
  String _savedNutritionGoal = '';
  List<String> _savedFoodPreferences = const [];
  List<String> _savedDietaryRestrictions = const [];
  List<String> _savedTasteProfile = const [];
  String _savedPreferredLanguage = '';
  String? _profileError;
  String? _historyError;
  List<ProfileHistoryItem> _historyItems = const [];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: _savedFullName);
    _emailController = TextEditingController(text: _savedEmail);
    _genderController = TextEditingController(text: _savedGender);
    _ageController = TextEditingController(text: _savedAge);
    _heightController = TextEditingController(text: _savedHeight);
    _weightController = TextEditingController(text: _savedWeight);
    _profileRemoteDataSource = ProfileRemoteDataSource(DioClient());
    _imagePicker = ImagePicker();
    _loadProfile();
  }

  @override
  bool get canAutoRefresh {
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        !_isEditingAccount &&
        !_isSavingProfile;
  }

  @override
  Future<void> onAutoRefresh() async {
    await _loadProfile(showLoading: false);
    if (_view == _ProfileView.history) {
      await _loadHistory(showLoading: false);
    }
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
    final isFoodPreferenceView = _view == _ProfileView.foodPreference;

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
                  child: isFoodPreferenceView
                      ? FoodPreferenceContent(
                          initialGoals: _savedFoodPreferences,
                          initialRestrictions: _savedDietaryRestrictions,
                          initialTasteProfiles: _savedTasteProfile,
                          initialNutritionGoal: _savedNutritionGoal,
                          onBack: _handleBack,
                          onSave: _saveFoodPreferences,
                        )
                      : IntrinsicHeight(child: _buildCurrentProfileView()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentProfileView() {
    return switch (_view) {
      _ProfileView.account => _AccountContent(
        isEditing: _isEditingAccount,
        isLoading: _isLoadingProfile,
        isSaving: _isSavingProfile,
        errorMessage: _profileError,
        fullNameController: _fullNameController,
        emailController: _emailController,
        genderController: _genderController,
        ageController: _ageController,
        heightController: _heightController,
        weightController: _weightController,
        onBack: _handleBack,
        onEdit: _enableAccountEditing,
        onEditPhoto: _handleEditPhoto,
        profilePhotoUrl: _savedProfilePhotoUrl,
        isUploadingPhoto: _isUploadingPhoto,
        onSave: _saveAccountChanges,
        onDiscard: _discardAccountChanges,
        onGenderChanged: _setGender,
      ),
      _ProfileView.history => _HistoryContent(
        onBack: _handleBack,
        isLoading: _isLoadingHistory,
        errorMessage: _historyError,
        items: _historyItems,
        onRetry: _loadHistory,
      ),
      _ProfileView.menu => _ProfileMenuContent(
        displayName: _displayName,
        isLoading: _isLoadingProfile,
        profilePhotoUrl: _savedProfilePhotoUrl,
        onBack: _handleBack,
        onAccountTap: _openAccount,
        onFoodPreferenceTap: _openFoodPreference,
        onHistoryTap: _openHistory,
        onLogoutTap: _handleLogoutTap,
        preferredLanguage: _languageLabel,
        onLanguageTap: _handleLanguageTap,
      ),
      _ProfileView.foodPreference => const SizedBox.shrink(),
    };
  }

  String get _displayName {
    return _firstPresentName([
      _savedFullName,
      FirebaseAuth.instance.currentUser?.displayName,
      _savedEmail,
      FirebaseAuth.instance.currentUser?.email,
      'User',
    ]);
  }

  String get _languageLabel {
    return switch (_savedPreferredLanguage.trim().toLowerCase()) {
      'id' || 'id_id' => 'Bahasa Indonesia',
      _ => 'English (US)',
    };
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

    if (_view == _ProfileView.foodPreference) {
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

  void _openFoodPreference() {
    setState(() => _view = _ProfileView.foodPreference);
  }

  void _openHistory() {
    setState(() => _view = _ProfileView.history);
    if (_historyItems.isEmpty && !_isLoadingHistory) {
      _loadHistory();
    }
  }

  void _enableAccountEditing() {
    setState(() => _isEditingAccount = true);
  }

  Future<void> _handleEditPhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1024,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);
      final profile = await _profileRemoteDataSource.uploadProfilePhoto(
        bytes: await image.readAsBytes(),
        filename: image.name.isEmpty ? 'profile-photo.jpg' : image.name,
      );
      if (!mounted) return;

      await _evictProfilePhotoCache([
        _savedProfilePhotoUrl,
        profile.profilePhotoUrl,
      ]);
      if (!mounted) return;

      _applyProfile(profile);
      setState(() => _isUploadingPhoto = false);
      AutoRefreshService.instance.refreshNow();
      _showSnackBar('Profile photo updated.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isUploadingPhoto = false);
      _showSnackBar(_profileSaveErrorMessage(error));
    }
  }

  void _setGender(String? gender) {
    if (gender == null) return;

    setState(() => _genderController.text = gender);
  }

  Future<void> _saveAccountChanges() async {
    if (_isSavingProfile) return;

    setState(() => _isSavingProfile = true);

    try {
      final profile = await _profileRemoteDataSource.updateProfile(
        name: _fullNameController.text.trim(),
        gender: _genderController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        heightCm: int.tryParse(_heightController.text.trim()),
        weightKg: int.tryParse(_weightController.text.trim()),
      );

      if (!mounted) return;

      _applyProfile(profile);
      setState(() {
        _isEditingAccount = false;
        _isSavingProfile = false;
        _profileError = null;
      });
      AutoRefreshService.instance.refreshNow();
      _showSnackBar('Profile updated.');
    } catch (error) {
      if (!mounted) return;

      final message = _profileSaveErrorMessage(error);
      setState(() {
        _isSavingProfile = false;
        _profileError = message;
      });
      _showSnackBar(message);
    }
  }

  Future<void> _saveFoodPreferences({
    required List<String> goals,
    required List<String> restrictions,
    required List<String> tasteProfiles,
    required String? nutritionGoal,
  }) async {
    final profile = await _profileRemoteDataSource.updatePreferences(
      foodPreferences: goals,
      dietaryRestrictions: restrictions,
      tasteProfile: tasteProfiles,
      nutritionGoal: nutritionGoal,
    );

    if (!mounted) return;

    _applyProfile(profile);
    AutoRefreshService.instance.refreshNow();
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

  Future<void> _handleLogoutTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const _LogoutConfirmationDialog(),
    );

    if (!mounted || confirmed != true) return;

    await Future.wait([
      FirebaseAuth.instance.signOut(),
      GoogleSignIn().signOut(),
    ]);
    await _secureStorage.delete(key: ApiConstants.firebaseIdTokenStorageKey);

    if (!mounted) return;
    context.goNamed(AppRouter.login);
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (_isEditingAccount || _isSavingProfile) return;

    if (showLoading) {
      setState(() {
        _isLoadingProfile = true;
        _profileError = null;
      });
    }

    try {
      var profile = await _loadSyncedProfile();
      if (!mounted) return;

      _applyProfile(profile);
      setState(() {
        if (showLoading) _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (_) {
      if (!mounted) return;

      if (showLoading) {
        _applyFirebaseFallback();
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Profile belum bisa dimuat dari database.';
        });
      }
    }
  }

  Future<void> _handleLanguageTap() async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LanguageOptionTile(
                  label: 'English (US)',
                  value: 'en',
                  selectedValue: _savedPreferredLanguage,
                ),
                _LanguageOptionTile(
                  label: 'Bahasa Indonesia',
                  value: 'id',
                  selectedValue: _savedPreferredLanguage,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedLanguage == null) return;

    try {
      final profile = await _profileRemoteDataSource.updateLanguage(
        selectedLanguage,
      );
      if (!mounted) return;

      _applyProfile(profile);
      AutoRefreshService.instance.refreshNow();
      _showSnackBar('Language preference updated.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(_profileSaveErrorMessage(error));
    }
  }

  Future<void> _loadHistory({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoadingHistory = true;
        _historyError = null;
      });
    }

    try {
      final items = await _profileRemoteDataSource.getRecentlyViewed();
      if (!mounted) return;

      setState(() {
        _historyItems = items;
        if (showLoading) _isLoadingHistory = false;
        _historyError = null;
      });
    } catch (_) {
      if (!mounted) return;

      if (showLoading || _historyItems.isEmpty) {
        setState(() {
          _historyError = 'History belum bisa dimuat dari database.';
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _applyProfile(ProfileUser profile) {
    _savedFullName = _firstPresentName([
      profile.name,
      profile.username,
      FirebaseAuth.instance.currentUser?.displayName,
      profile.email,
      FirebaseAuth.instance.currentUser?.email,
    ]);
    _savedEmail = _firstPresentText([
      profile.email,
      FirebaseAuth.instance.currentUser?.email,
    ]);
    _savedGender = profile.gender;
    _savedAge = profile.age?.toString() ?? '';
    _savedHeight = profile.heightCm?.toString() ?? '';
    _savedWeight = profile.weightKg?.toString() ?? '';
    _savedProfilePhotoUrl = profile.profilePhotoUrl;
    _savedNutritionGoal = profile.nutritionGoal;
    _savedFoodPreferences = profile.foodPreferences;
    _savedDietaryRestrictions = profile.dietaryRestrictions;
    _savedTasteProfile = profile.tasteProfile;
    _savedPreferredLanguage = profile.preferredLanguage;
    _discardAccountChanges();
  }

  Future<void> _evictProfilePhotoCache(Iterable<String> urls) async {
    final seenUrls = <String>{};

    for (final rawUrl in urls) {
      final url = rawUrl.trim();
      if (url.isEmpty || !seenUrls.add(url)) continue;

      await NetworkImage(url).evict();
    }
  }

  void _applyFirebaseFallback() {
    final user = FirebaseAuth.instance.currentUser;
    _savedFullName = _firstPresentName([
      user?.displayName,
      user?.email,
      'User',
    ]);
    _savedEmail = user?.email?.trim() ?? '';
    _savedProfilePhotoUrl = user?.photoURL?.trim() ?? '';
    _savedNutritionGoal = '';
    _savedFoodPreferences = const [];
    _savedDietaryRestrictions = const [];
    _savedTasteProfile = const [];
    _savedPreferredLanguage = '';
    _discardAccountChanges();
  }

  Future<ProfileUser> _loadSyncedProfile() async {
    try {
      return await _profileRemoteDataSource.getProfile();
    } catch (_) {
      await _profileRemoteDataSource.syncUser();
      return _profileRemoteDataSource.getProfile();
    }
  }

  String _firstPresentName(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || text.toLowerCase() == 'unknown') continue;

      if (text.contains('@')) {
        final emailName = text.split('@').first.trim();
        if (emailName.isNotEmpty) return emailName;
        continue;
      }

      return text;
    }

    return 'User';
  }

  String _firstPresentText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'unknown') return text;
    }

    return '';
  }

  String _profileSaveErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final backendMessage = _backendErrorMessage(data);
      if (backendMessage != null) return backendMessage;

      if (statusCode == 401) {
        return 'Sesi login tidak valid. Silakan logout lalu login lagi.';
      }
      if (statusCode == 404) {
        return 'Data user belum tersinkron. Coba login ulang.';
      }
      if (statusCode != null) {
        return 'Gagal menyimpan profile. Server memberi status $statusCode.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Tidak bisa terhubung ke backend. Cek Wi-Fi/IP backend.';
      }
    }

    return 'Gagal menyimpan profile. Cek koneksi lalu coba lagi.';
  }

  String? _backendErrorMessage(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join('\n');
      }
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) return error;
    }

    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileMenuContent extends StatelessWidget {
  const _ProfileMenuContent({
    required this.displayName,
    required this.isLoading,
    required this.profilePhotoUrl,
    required this.onBack,
    required this.onAccountTap,
    required this.onFoodPreferenceTap,
    required this.onHistoryTap,
    required this.onLogoutTap,
    required this.preferredLanguage,
    required this.onLanguageTap,
  });

  final String displayName;
  final bool isLoading;
  final String profilePhotoUrl;
  final VoidCallback onBack;
  final VoidCallback onAccountTap;
  final VoidCallback onFoodPreferenceTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onLogoutTap;
  final String preferredLanguage;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onPressed: onBack),
        const SizedBox(height: 22),
        Center(
          child: isLoading
              ? const AppSkeleton(child: AppSkeletonCircle(size: 108))
              : _ProfileAvatar(imageUrl: profilePhotoUrl),
        ),
        const SizedBox(height: 17),
        Center(
          child: isLoading
              ? const AppSkeleton(
                  child: AppSkeletonLine(width: 148, height: 24),
                )
              : Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          onTap: onFoodPreferenceTap,
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
          onTap: onLogoutTap,
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
                preferredLanguage,
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
          onTap: onLanguageTap,
        ),
      ],
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.value,
    required this.selectedValue,
  });

  final String label;
  final String value;
  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue.trim().toLowerCase() == value;

    return ListTile(
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: const Color(0xFFFAF7F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 37, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure want to\nlogout?',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF242424),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFAF7F7),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: Colors.black.withValues(alpha: 0.28),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.onBack,
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.onRetry,
  });

  final VoidCallback onBack;
  final bool isLoading;
  final String? errorMessage;
  final List<ProfileHistoryItem> items;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final sections = _groupItems(items);

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
        CustomSearchBar(onTap: () => context.pushNamed(AppRouter.search)),
        const SizedBox(height: 24),
        if (isLoading)
          const _HistoryLoadingList()
        else if (errorMessage != null)
          _ProfileStatusBox(message: errorMessage!, onRetry: onRetry)
        else if (items.isEmpty)
          const _ProfileStatusBox(message: 'No recently viewed foods yet.')
        else
          ...sections.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistorySection(title: entry.key, items: entry.value),
            ),
          ),
      ],
    );
  }

  Map<String, List<ProfileHistoryItem>> _groupItems(
    List<ProfileHistoryItem> items,
  ) {
    final sections = <String, List<ProfileHistoryItem>>{};
    for (final item in items) {
      final key = _dateLabel(item.viewedAt);
      sections.putIfAbsent(key, () => []).add(item);
    }

    return sections;
  }

  String _dateLabel(DateTime? viewedAt) {
    if (viewedAt == null) return 'Recently';

    final localDate = viewedAt.toLocal();
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final viewedDay = DateTime(localDate.year, localDate.month, localDate.day);
    final difference = currentDay.difference(viewedDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    return '${localDate.day} ${_monthName(localDate.month)} ${localDate.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.items});

  final String title;
  final List<ProfileHistoryItem> items;

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
            title: item.name,
            subtitle: item.description,
            price: item.formattedPrice,
            ratingText: item.ratingText,
            onTap: item.foodId.isEmpty
                ? null
                : () => context.pushNamed(
                    AppRouter.foodDetail,
                    pathParameters: {'id': item.foodId},
                  ),
          ),
        ),
      ],
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.isEditing,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
    required this.fullNameController,
    required this.emailController,
    required this.genderController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.profilePhotoUrl,
    required this.isUploadingPhoto,
    required this.onBack,
    required this.onEdit,
    required this.onEditPhoto,
    required this.onSave,
    required this.onDiscard,
    required this.onGenderChanged,
  });

  final bool isEditing;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController genderController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final String profilePhotoUrl;
  final bool isUploadingPhoto;
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
        if (isLoading)
          const _AccountLoadingContent()
        else ...[
          Center(
            child: _ProfileAvatar(
              size: 124,
              imageUrl: profilePhotoUrl,
              showEditButton: isEditing,
              isUploading: isUploadingPhoto,
              onEditPhoto: isUploadingPhoto ? null : onEditPhoto,
            ),
          ),
          const SizedBox(height: 63),
        ],
        if (!isLoading && errorMessage != null) ...[
          _ProfileStatusBox(message: errorMessage!),
          const SizedBox(height: 22),
        ],
        if (!isLoading) ...[
          _AccountField(
            label: 'Full Name',
            controller: fullNameController,
            enabled: isEditing,
          ),
          const SizedBox(height: 22),
          _AccountField(
            label: 'Email',
            controller: emailController,
            enabled: false,
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
        ],
        const Spacer(),
        const SizedBox(height: 36),
        if (!isLoading)
          if (isEditing) ...[
            _PrimaryProfileButton(
              text: isSaving ? 'Saving...' : 'Save Changes',
              onPressed: isSaving ? null : onSave,
            ),
            const SizedBox(height: 18),
            _SecondaryProfileButton(
              text: 'Discard Changes',
              onPressed: isSaving ? null : onDiscard,
            ),
          ] else
            _PrimaryProfileButton(text: 'Edit', onPressed: onEdit),
      ],
    );
  }
}

class _HistoryLoadingList extends StatelessWidget {
  const _HistoryLoadingList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonRecommendationCard(),
        AppSkeletonRecommendationCard(),
        AppSkeletonRecommendationCard(),
      ],
    );
  }
}

class _AccountLoadingContent extends StatelessWidget {
  const _AccountLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(
      child: Column(
        children: [
          Center(child: AppSkeletonCircle(size: 124)),
          SizedBox(height: 63),
          AppSkeletonBox(height: 54, borderRadius: 8),
          SizedBox(height: 22),
          AppSkeletonBox(height: 54, borderRadius: 8),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 54, borderRadius: 8)),
              SizedBox(width: 19),
              Expanded(child: AppSkeletonBox(height: 54, borderRadius: 8)),
            ],
          ),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 54, borderRadius: 8)),
              SizedBox(width: 19),
              Expanded(child: AppSkeletonBox(height: 54, borderRadius: 8)),
            ],
          ),
          SizedBox(height: 36),
          AppSkeletonBox(height: 52, borderRadius: 5),
        ],
      ),
    );
  }
}

class _ProfileStatusBox extends StatelessWidget {
  const _ProfileStatusBox({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DEDE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
        ],
      ),
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
    this.imageUrl = '',
    this.showEditButton = false,
    this.isUploading = false,
    this.onEditPhoto,
  });

  final double size;
  final String imageUrl;
  final bool showEditButton;
  final bool isUploading;
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
          if (imageUrl.trim().isNotEmpty)
            ClipOval(
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _DefaultProfileAvatar(size: size);
                },
              ),
            )
          else
            _DefaultProfileAvatar(size: size),
          if (isUploading)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
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

class _DefaultProfileAvatar extends StatelessWidget {
  const _DefaultProfileAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
  final VoidCallback? onPressed;

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
  final VoidCallback? onPressed;

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
