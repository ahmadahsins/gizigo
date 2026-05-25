import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_router.dart';
import '../../../location/domain/entities/location_item.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class MerchantRegisterScreen extends StatefulWidget {
  const MerchantRegisterScreen({super.key});

  @override
  State<MerchantRegisterScreen> createState() => _MerchantRegisterScreenState();
}

class _MerchantRegisterScreenState extends State<MerchantRegisterScreen> {
  static const _defaultMerchantLocation = _MerchantLocation(
    name: 'Nasi Goreng Den Bagoes',
    address:
        'Jl. Blimbingan No.37, Blimbing Sari, Caturtunggal, Depok, Sleman, DI Yogyakarta 55281',
    latitude: -7.76892,
    longitude: 110.38298,
  );

  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;
  LocationItem? _selectedMerchantLocation;

  _MerchantLocation get _merchantLocationPreview {
    final selectedLocation = _selectedMerchantLocation;
    final businessName = _businessNameController.text.trim();
    final address = _addressController.text.trim();

    return _MerchantLocation(
      name: businessName.isNotEmpty
          ? businessName
          : selectedLocation?.name ?? _defaultMerchantLocation.name,
      address: address.isNotEmpty
          ? address
          : selectedLocation?.address ?? _defaultMerchantLocation.address,
      latitude: selectedLocation?.latitude ?? _defaultMerchantLocation.latitude,
      longitude:
          selectedLocation?.longitude ?? _defaultMerchantLocation.longitude,
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    final merchantLocation = _selectedMerchantLocation;
    if (merchantLocation == null) {
      _showError('Pilih titik lokasi merchant dulu.');
      return;
    }

    if (Firebase.apps.isEmpty) {
      _showError('Firebase belum dikonfigurasi di frontend.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _businessEmailController.text.trim(),
            password: _passwordController.text,
          );

      final user = credential.user;
      await user?.updateDisplayName(_businessNameController.text.trim());
      final idToken = await user?.getIdToken(true);

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-token',
          message: 'Firebase token tidak ditemukan.',
        );
      }

      await _secureStorage.write(
        key: ApiConstants.firebaseIdTokenStorageKey,
        value: idToken,
      );

      await DioClient(storage: _secureStorage).post(
        ApiConstants.signup,
        data: {
          'account_type': 'merchant',
          'merchant': {
            'name': _businessNameController.text.trim(),
            'address': _addressController.text.trim(),
            'lat': merchantLocation.latitude,
            'lng': merchantLocation.longitude,
          },
        },
      );

      if (!mounted) return;
      context.goNamed(AppRouter.home);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showError(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Registrasi merchant gagal. Cek koneksi dan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _sendPasswordResetEmail() async {
    final email = _businessEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Isi business email yang valid dulu.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link reset password sudah dikirim.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showError(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Reset password gagal. Coba lagi.');
    }
  }

  String? _requiredText(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Business email wajib diisi';
    if (!email.contains('@')) return 'Business email belum valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email belum valid.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'missing-token':
        return error.message ?? 'Firebase token tidak ditemukan.';
      default:
        return error.message ?? 'Registrasi merchant gagal. Coba lagi.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/Logo - Green.svg',
                          height: 56,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Sign up as Merchant',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              label: 'Business Name',
                              hintText: 'Enter your Business Name here',
                              controller: _businessNameController,
                              onChanged: (_) => setState(() {}),
                              validator: (value) =>
                                  _requiredText(value, 'Business name'),
                            ),
                            const SizedBox(height: 20),
                            AuthTextField(
                              label: 'Business Email',
                              hintText: 'Enter your Business Email here',
                              controller: _businessEmailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 20),
                            AuthTextField(
                              label: 'Password',
                              hintText: 'Enter your Password here',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              labelSuffix: GestureDetector(
                                onTap: _sendPasswordResetEmail,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[500],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            AuthTextField(
                              label: 'Address',
                              hintText: 'Enter your Full Address here',
                              controller: _addressController,
                              onChanged: (_) => setState(() {}),
                              validator: (value) =>
                                  _requiredText(value, 'Address'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MerchantLocationPreview(
                        location: _merchantLocationPreview,
                        hasSelectedLocation: _selectedMerchantLocation != null,
                        onTap: _openLocationPicker,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        text: _isLoading ? 'Signing up...' : 'Sign up',
                        onPressed: _signUp,
                      ),
                      const SizedBox(height: 32),
                      const _MerchantSignInPrompt(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MerchantLocation {
  const _MerchantLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);
}

class _MerchantLocationPreview extends StatelessWidget {
  const _MerchantLocationPreview({
    required this.location,
    required this.hasSelectedLocation,
    required this.onTap,
  });

  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'id.gizigo.app';

  final _MerchantLocation location;
  final bool hasSelectedLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD9D9D9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: FlutterMap(
                          key: ValueKey(
                            '${location.latitude},${location.longitude}',
                          ),
                          options: MapOptions(
                            initialCenter: location.point,
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _osmTileUrl,
                              userAgentPackageName: _userAgentPackageName,
                              maxNativeZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: location.point,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 18, 14),
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
                            location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF303030),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
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

class _MerchantSignInPrompt extends StatelessWidget {
  const _MerchantSignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Have a merchant account? ',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.goNamed(AppRouter.login),
          child: Text(
            'Sign in',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
