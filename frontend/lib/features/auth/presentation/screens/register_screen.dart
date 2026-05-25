import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_dropdown_field.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedGender;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    if (Firebase.apps.isEmpty) {
      _showError('Firebase belum dikonfigurasi di frontend.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = credential.user;
      await user?.updateDisplayName(_fullNameController.text.trim());
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

      await _syncBackendProfile();

      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showError(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Registrasi gagal. Cek koneksi dan coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return;

    if (Firebase.apps.isEmpty) {
      _showError('Firebase belum dikonfigurasi di frontend.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken(true);

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
      await DioClient(storage: _secureStorage).post(ApiConstants.authSync);

      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showError(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Google sign up gagal. Cek konfigurasi dan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _requiredText(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? _validateNumber(
    String? value,
    String label, {
    required num min,
    required num max,
  }) {
    final text = value?.trim() ?? '';
    final number = num.tryParse(text);
    if (text.isEmpty) {
      return '$label wajib diisi';
    }
    if (number == null) {
      return '$label harus angka';
    }
    if (number < min || number > max) {
      return '$label harus $min-$max';
    }
    return null;
  }

  Future<void> _syncBackendProfile() async {
    final client = DioClient(storage: _secureStorage);
    await client.post(
      ApiConstants.signup,
      data: const {'account_type': 'customer'},
    );
    await client.patch(
      ApiConstants.usersMe,
      data: {
        'name': _fullNameController.text.trim(),
        'gender': _apiGender(_selectedGender),
        'age': int.tryParse(_ageController.text.trim()),
        'height_cm': int.tryParse(_heightController.text.trim()),
        'weight_kg': int.tryParse(_weightController.text.trim()),
        'onboarding_completed': true,
      },
    );
  }

  String _apiGender(String? gender) {
    return switch (gender?.trim().toLowerCase()) {
      'male' => 'MALE',
      'female' => 'FEMALE',
      _ => 'PREFER_NOT_TO_SAY',
    };
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
        return error.message ?? 'Registrasi gagal. Coba lagi.';
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

                      // Logo
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/Logo - Green.svg',
                          height: 56,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title Text
                      Center(
                        child: Text(
                          'Create your Account',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthTextField(
                              label: 'Full Name',
                              hintText: 'Enter your Full Name here',
                              controller: _fullNameController,
                              validator: (value) =>
                                  _requiredText(value, 'Full name'),
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'Email',
                              hintText: 'Enter your Email here',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                if (!email.contains('@')) {
                                  return 'Email belum valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              label: 'Password',
                              hintText: 'Enter your Password here',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AuthDropdownField(
                                    label: 'Gender',
                                    hintText: 'Select one',
                                    items: const ['Male', 'Female'],
                                    initialValue: _selectedGender,
                                    validator: (value) =>
                                        value == null ? 'Pilih gender' : null,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedGender = newValue;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AuthTextField(
                                    label: 'Age',
                                    hintText: 'Age (year)',
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumber(
                                      value,
                                      'Age',
                                      min: 13,
                                      max: 120,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AuthTextField(
                                    label: 'Height',
                                    hintText: 'Height (cm)',
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumber(
                                      value,
                                      'Height',
                                      min: 50,
                                      max: 260,
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'cm',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AuthTextField(
                                    label: 'Weight',
                                    hintText: 'Weight (kg)',
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) => _validateNumber(
                                      value,
                                      'Weight',
                                      min: 20,
                                      max: 400,
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'kg',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign up Button
                      PrimaryButton(
                        text: _isLoading ? 'Signing up...' : 'Sign up',
                        onPressed: _signUp,
                      ),
                      const SizedBox(height: 24),

                      // or Sign up with
                      Center(
                        child: Text(
                          'or Sign up with',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google Sign up Button
                      GoogleButton(
                        text: 'Sign up with Google',
                        onPressed: _signUpWithGoogle,
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Bottom Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                            },
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
                      ),
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
