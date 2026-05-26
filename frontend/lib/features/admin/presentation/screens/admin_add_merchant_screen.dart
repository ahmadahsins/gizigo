import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_router.dart';
import '../../../location/domain/entities/location_item.dart';
import '../../data/admin_remote_data_source.dart';

class AdminAddMerchantScreen extends StatefulWidget {
  const AdminAddMerchantScreen({super.key});

  @override
  State<AdminAddMerchantScreen> createState() => _AdminAddMerchantScreenState();
}

class _AdminAddMerchantScreenState extends State<AdminAddMerchantScreen> {
  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'id.gizigo.app';

  final _formKey = GlobalKey<FormState>();
  late final AdminRemoteDataSource _remoteDataSource;
  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  LocationItem? _selectedMerchantLocation;
  bool _isSaving = false;

  LocationItem? get _merchantLocationPreview {
    final selectedLocation = _selectedMerchantLocation;
    if (selectedLocation == null) return null;

    final businessName = _businessNameController.text.trim();
    final address = _addressController.text.trim();

    return LocationItem(
      name: businessName.isNotEmpty ? businessName : selectedLocation.name,
      address: address.isNotEmpty ? address : selectedLocation.address,
      distanceLabel: selectedLocation.distanceLabel,
      latitude: selectedLocation.latitude,
      longitude: selectedLocation.longitude,
    );
  }

  @override
  void initState() {
    super.initState();
    _remoteDataSource = AdminRemoteDataSource(DioClient());
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;

    final merchantLocation = _selectedMerchantLocation;
    if (merchantLocation == null) {
      _showSnackBar('Pilih titik lokasi merchant dulu.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final merchant = await _remoteDataSource.createMerchant(
        name: _businessNameController.text.trim(),
        email: _businessEmailController.text.trim(),
        password: _passwordController.text,
        address: _addressController.text.trim(),
        latitude: merchantLocation.latitude,
        longitude: merchantLocation.longitude,
      );
      if (!mounted) return;

      Navigator.of(context).pop(merchant);
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showSnackBar(_errorMessage(error));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLocationPicker() async {
    final selectedLocation = await context.pushNamed<LocationItem>(
      AppRouter.selectLocationMap,
      extra: _selectedMerchantLocation,
    );
    if (!mounted || selectedLocation == null) return;

    setState(() {
      _selectedMerchantLocation = selectedLocation;
      _addressController.text = selectedLocation.address;
    });
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'Email merchant sudah terdaftar.',
        'invalid-email' => 'Format email merchant belum valid.',
        'weak-password' => 'Password minimal 6 karakter.',
        'firebase-not-configured' =>
          error.message ?? 'Firebase belum dikonfigurasi.',
        'missing-token' =>
          error.message ?? 'Firebase token merchant tidak ditemukan.',
        _ => error.message ?? 'Gagal membuat akun merchant.',
      };
    }

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
        return 'Gagal menambahkan merchant. Server memberi status $statusCode.';
      }
    }

    return 'Gagal menambahkan merchant. Cek data dan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
            children: [
              _AddMerchantHeader(
                onBack: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 32),
              _FieldLabel('Business Name'),
              const SizedBox(height: 8),
              _MerchantTextField(
                controller: _businessNameController,
                hintText: 'Enter Business Name here',
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Business name wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              _FieldLabel('Business Email'),
              const SizedBox(height: 8),
              _MerchantTextField(
                controller: _businessEmailController,
                hintText: 'Enter Business Email here',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Business email wajib diisi.';
                  if (!text.contains('@')) return 'Email tidak valid.';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              _FieldLabel('Password'),
              const SizedBox(height: 8),
              _MerchantTextField(
                controller: _passwordController,
                hintText: 'Enter Password here',
                obscureText: true,
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'Password minimal 6 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              _FieldLabel('Address'),
              const SizedBox(height: 8),
              _MerchantTextField(
                controller: _addressController,
                hintText: 'Enter Full Address here',
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Address wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              _MerchantMapPreview(
                location: _merchantLocationPreview,
                hasSelectedLocation: _selectedMerchantLocation != null,
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 28),
              _AddMerchantButton(isLoading: _isSaving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMerchantHeader extends StatelessWidget {
  const _AddMerchantHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 30,
              color: Color(0xFF202020),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Add Merchant',
          style: GoogleFonts.inter(
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF202020),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        height: 1,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF242424),
      ),
    );
  }
}

class _MerchantTextField extends StatelessWidget {
  const _MerchantTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF929292),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _MerchantMapPreview extends StatelessWidget {
  const _MerchantMapPreview({
    required this.location,
    required this.hasSelectedLocation,
    required this.onTap,
  });

  final LocationItem? location;
  final bool hasSelectedLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedLocation = location;
    final point = selectedLocation == null
        ? null
        : LatLng(selectedLocation.latitude, selectedLocation.longitude);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
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
                      child: selectedLocation == null
                          ? const _EmptyMerchantMapPreview()
                          : AbsorbPointer(
                              child: FlutterMap(
                                key: ValueKey(
                                  '${selectedLocation.latitude},${selectedLocation.longitude}',
                                ),
                                options: MapOptions(
                                  initialCenter: point!,
                                  initialZoom: 16,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: _AdminAddMerchantScreenState
                                        ._osmTileUrl,
                                    userAgentPackageName:
                                        _AdminAddMerchantScreenState
                                            ._userAgentPackageName,
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
                            hasSelectedLocation
                                ? 'Change location'
                                : 'Choose location',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
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
                            selectedLocation?.name ?? 'Lokasi belum dipilih',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF303030),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            selectedLocation?.address ??
                                'Tap untuk memilih titik lokasi merchant.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5F5F5F),
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
      ),
    );
  }
}

class _EmptyMerchantMapPreview extends StatelessWidget {
  const _EmptyMerchantMapPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFEDEAEA)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.add_location_alt_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pilih lokasi merchant',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMerchantButton extends StatelessWidget {
  const _AddMerchantButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.62),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
            : Text(
                'Add Merchant',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
