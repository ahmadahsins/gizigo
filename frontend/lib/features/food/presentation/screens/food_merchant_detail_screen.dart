import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_router.dart';
import '../../../location/domain/entities/location_item.dart';
import '../../data/models/food_detail.dart';

class FoodMerchantDetailScreen extends StatefulWidget {
  const FoodMerchantDetailScreen({
    super.key,
    required this.merchant,
    this.onSaveChanges,
    this.onDelete,
    this.onLogout,
  });

  final FoodMerchantDetail merchant;
  final Future<FoodMerchantDetail> Function(
    FoodMerchantDetail merchant,
    String? newPassword,
  )?
  onSaveChanges;
  final Future<bool> Function()? onDelete;
  final Future<void> Function()? onLogout;

  static const _defaultPoint = LatLng(-7.76892, 110.38298);
  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'id.gizigo.app';

  @override
  State<FoodMerchantDetailScreen> createState() =>
      _FoodMerchantDetailScreenState();
}

class _FoodMerchantDetailScreenState extends State<FoodMerchantDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late FoodMerchantDetail _merchant;
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessEmailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _addressController;
  LocationItem? _selectedLocation;
  bool _isEditing = false;
  bool _isSaving = false;

  LocationItem get _currentLocation {
    final selectedLocation = _selectedLocation;
    final name = _businessNameController.text.trim();
    final address = _addressController.text.trim();

    return LocationItem(
      name: name.isNotEmpty ? name : _merchant.displayName(),
      address: address.isNotEmpty
          ? address
          : _merchant.address.isNotEmpty
          ? _merchant.address
          : 'Alamat merchant belum tersedia.',
      distanceLabel: selectedLocation?.distanceLabel ?? '0.0km',
      latitude:
          selectedLocation?.latitude ??
          _merchant.latitude ??
          FoodMerchantDetailScreen._defaultPoint.latitude,
      longitude:
          selectedLocation?.longitude ??
          _merchant.longitude ??
          FoodMerchantDetailScreen._defaultPoint.longitude,
    );
  }

  @override
  void initState() {
    super.initState();
    _merchant = widget.merchant;
    _businessNameController = TextEditingController();
    _businessEmailController = TextEditingController();
    _passwordController = TextEditingController();
    _addressController = TextEditingController();
    _syncControllers();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _businessNameController.text = _merchant.displayName();
    _businessEmailController.text = _merchant.email;
    _passwordController.clear();
    _addressController.text = _merchant.address;
    _selectedLocation = null;
  }

  @override
  Widget build(BuildContext context) {
    final isBusinessProfile = widget.onLogout != null;
    final point = _merchant.hasLocation
        ? LatLng(_merchant.latitude!, _merchant.longitude!)
        : FoodMerchantDetailScreen._defaultPoint;
    final name = _merchant.name.isEmpty ? 'Merchant' : _merchant.name;
    final email = _merchant.email.isEmpty ? '-' : _merchant.email;
    final address = _merchant.address.isEmpty
        ? 'Alamat merchant belum tersedia.'
        : _merchant.address;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
            children: [
              _MerchantDetailHeader(
                title: isBusinessProfile
                    ? _isEditing
                          ? 'Edit Business Profile'
                          : 'Business Profile'
                    : _isEditing
                    ? 'Edit Merchant'
                    : 'Detail Merchant',
                onBack: _handleBack,
              ),
              const SizedBox(height: 28),
              if (_isEditing)
                ..._buildEditFields(showPassword: !isBusinessProfile)
              else
                ..._buildReadonlyFields(
                  name,
                  email,
                  address,
                  showPassword: !isBusinessProfile,
                ),
              const SizedBox(height: 22),
              _MerchantMapCard(
                name: _isEditing ? _currentLocation.name : name,
                address: _isEditing ? _currentLocation.address : address,
                point: _isEditing
                    ? LatLng(
                        _currentLocation.latitude,
                        _currentLocation.longitude,
                      )
                    : point,
                onTap: _isEditing ? _openLocationPicker : null,
              ),
              SizedBox(height: isBusinessProfile ? 83 : 27),
              if (_isEditing) ...[
                _MerchantActionButton(
                  label: 'Save Changes',
                  color: AppColors.primary,
                  isLoading: _isSaving,
                  onPressed: _saveChanges,
                ),
                const SizedBox(height: 24),
                _MerchantActionButton(
                  label: 'Discard Changes',
                  color: AppColors.primary,
                  isOutlined: true,
                  onPressed: _discardChanges,
                ),
              ] else ...[
                _MerchantActionButton(
                  label: isBusinessProfile ? 'Edit' : 'Edit Merchant',
                  color: AppColors.primary,
                  onPressed: _startEditing,
                ),
                const SizedBox(height: 24),
                _MerchantActionButton(
                  label: isBusinessProfile ? 'Logout' : 'Delete',
                  color: const Color(0xFFCC1B1F),
                  isLoading: _isSaving,
                  onPressed: isBusinessProfile
                      ? _logoutMerchant
                      : _deleteMerchant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReadonlyFields(
    String name,
    String email,
    String address, {
    required bool showPassword,
  }) {
    return [
      _MerchantReadonlyField(label: 'Business Name', value: name),
      const SizedBox(height: 23),
      _MerchantReadonlyField(label: 'Business Email', value: email),
      if (showPassword) ...[
        const SizedBox(height: 23),
        const _MerchantReadonlyField(
          label: 'Password',
          value: 'Tidak ditampilkan demi keamanan',
        ),
      ],
      const SizedBox(height: 23),
      _MerchantReadonlyField(
        label: 'Address',
        value: address,
        minHeight: showPassword ? 80 : 50,
        maxLines: showPassword ? 3 : 1,
      ),
    ];
  }

  List<Widget> _buildEditFields({required bool showPassword}) {
    return [
      _MerchantEditableField(
        label: 'Business Name',
        controller: _businessNameController,
        hintText: 'Enter Business Name here',
        onChanged: (_) => setState(() {}),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) return 'Business name wajib diisi.';
          return null;
        },
      ),
      const SizedBox(height: 22),
      _MerchantEditableField(
        label: 'Business Email',
        controller: _businessEmailController,
        hintText: 'Enter Business Email here',
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isNotEmpty && !text.contains('@')) {
            return 'Email tidak valid.';
          }
          return null;
        },
      ),
      if (showPassword) ...[
        const SizedBox(height: 22),
        _MerchantEditableField(
          label: 'Password',
          controller: _passwordController,
          hintText: 'Kosongkan jika tidak ingin mengganti password',
          obscureText: true,
          validator: (value) {
            final text = value ?? '';
            if (text.isNotEmpty && text.length < 6) {
              return 'Password minimal 6 karakter.';
            }
            return null;
          },
        ),
      ],
      const SizedBox(height: 22),
      _MerchantEditableField(
        label: 'Address',
        controller: _addressController,
        hintText: 'Enter Full Address here',
        maxLines: showPassword ? 2 : 1,
        onChanged: (_) => setState(() {}),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) return 'Address wajib diisi.';
          return null;
        },
      ),
    ];
  }

  void _handleBack() {
    if (_isEditing) {
      _discardChanges();
      return;
    }

    Navigator.of(context).pop(_merchant);
  }

  void _startEditing() {
    _syncControllers();
    setState(() => _isEditing = true);
  }

  void _discardChanges() {
    _syncControllers();
    setState(() {
      _isEditing = false;
      _isSaving = false;
    });
  }

  Future<void> _openLocationPicker() async {
    final selectedLocation = await context.pushNamed<LocationItem>(
      AppRouter.selectLocationMap,
      extra: _currentLocation,
    );
    if (!mounted || selectedLocation == null) return;

    setState(() {
      _selectedLocation = selectedLocation;
      _addressController.text = selectedLocation.address;
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    final saveChanges = widget.onSaveChanges;
    if (saveChanges == null) {
      _showUnavailable(context, 'Edit Merchant');
      return;
    }

    final location = _currentLocation;
    final updated = FoodMerchantDetail(
      name: _businessNameController.text.trim(),
      email: _businessEmailController.text.trim(),
      address: _addressController.text.trim(),
      photoUrl: _merchant.photoUrl,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    final newPassword = _passwordController.text.trim().isEmpty
        ? null
        : _passwordController.text.trim();

    setState(() => _isSaving = true);
    try {
      final saved = await saveChanges(updated, newPassword);
      if (!mounted) return;

      setState(() {
        _merchant = saved;
        _isEditing = false;
        _isSaving = false;
      });
      _syncControllers();
      _showToast('Data merchant berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showToast(_errorMessage(error), isError: true);
    }
  }

  Future<void> _deleteMerchant() async {
    final delete = widget.onDelete;
    if (delete == null) {
      _showUnavailable(context, 'Delete');
      return;
    }

    final confirmed = await _confirmDeleteMerchant();
    if (!mounted || confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final permanentlyDeleted = await delete();
      if (!mounted) return;

      Navigator.of(context).pop(permanentlyDeleted ? 'delete' : 'hide');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showToast(_errorMessage(error), isError: true);
    }
  }

  Future<void> _logoutMerchant() async {
    final logout = widget.onLogout;
    if (logout == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await logout();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showToast('Logout gagal. Coba lagi.', isError: true);
    }
  }

  Future<bool?> _confirmDeleteMerchant() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Hapus merchant?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Merchant "${_merchant.displayName()}" akan dihapus dari dashboard admin.',
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF606060),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFCC1B1F),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUnavailable(BuildContext context, String action) {
    _showToast('$action belum tersedia.', isError: true);
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _errorMessage(Object error) {
    if (error is StateError) return error.message;

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return 'Gagal menyimpan merchant. Server memberi status $statusCode.';
      }
    }

    return 'Gagal menyimpan merchant. Cek data dan coba lagi.';
  }
}

class _MerchantDetailHeader extends StatelessWidget {
  const _MerchantDetailHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF202124),
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 17),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF202124),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _MerchantReadonlyField extends StatelessWidget {
  const _MerchantReadonlyField({
    required this.label,
    required this.value,
    this.minHeight = 50,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final double minHeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isSingleLine = maxLines == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF242424),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          height: isSingleLine ? minHeight : null,
          constraints: isSingleLine
              ? null
              : BoxConstraints(minHeight: minHeight),
          alignment: isSingleLine ? Alignment.centerLeft : Alignment.topLeft,
          padding: isSingleLine
              ? const EdgeInsets.symmetric(horizontal: 13)
              : const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1F1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8C6C6)),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF979797),
              height: isSingleLine ? 1 : 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantEditableField extends StatelessWidget {
  const _MerchantEditableField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF242424),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          validator: validator,
          onChanged: onChanged,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
            height: 1.25,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF929292),
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F1F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC8C6C6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantMapCard extends StatelessWidget {
  const _MerchantMapCard({
    required this.name,
    required this.address,
    required this.point,
    this.onTap,
  });

  final String name;
  final String address;
  final LatLng point;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mapCard = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1F1),
          border: Border.all(color: const Color(0xFFE1DEDE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 193,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: FlutterMap(
                        key: ValueKey('${point.latitude},${point.longitude}'),
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: FoodMerchantDetailScreen._osmTileUrl,
                            userAgentPackageName:
                                FoodMerchantDetailScreen._userAgentPackageName,
                            maxNativeZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 56,
                                height: 56,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 56,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            'Change location',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 63),
              padding: const EdgeInsets.fromLTRB(25, 11, 19, 12),
              color: const Color(0xFFF5F1F1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF303030),
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5F5F5F),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return mapCard;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: mapCard,
    );
  }
}

class _MerchantActionButton extends StatelessWidget {
  const _MerchantActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOutlined ? Colors.white : color,
            foregroundColor: isOutlined ? color : Colors.white,
            disabledBackgroundColor: color.withValues(alpha: 0.62),
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size.fromHeight(52),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: isOutlined
                  ? BorderSide(color: color, width: 1.6)
                  : BorderSide.none,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: isOutlined ? color : Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
