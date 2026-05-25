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
import '../../../../router/app_router.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    if (Firebase.apps.isEmpty) {
      _showError('Firebase belum dikonfigurasi di frontend.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final idToken = await credential.user?.getIdToken(true);

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
      _showError('Login gagal. Cek koneksi dan coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
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
      _showError('Google sign in gagal. Cek konfigurasi dan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Isi email yang valid dulu.');
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

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Format email belum valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'missing-token':
        return error.message ?? 'Firebase token tidak ditemukan.';
      default:
        return error.message ?? 'Login gagal. Coba lagi.';
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

                      // Welcome Text
                      Center(
                        child: Text(
                          'Welcome back!',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            const SizedBox(height: 20),
                            AuthTextField(
                              label: 'Password',
                              hintText: 'Enter your Password here',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Password wajib diisi';
                                }
                                return null;
                              },
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign in Button
                      PrimaryButton(
                        text: _isLoading ? 'Signing in...' : 'Sign in',
                        onPressed: _signIn,
                      ),
                      const SizedBox(height: 48),

                      // or Sign in with
                      Center(
                        child: Text(
                          'or Sign in with',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google Sign in Button
                      GoogleButton(
                        text: 'Sign in with Google',
                        onPressed: _signInWithGoogle,
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Bottom Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/register');
                            },
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 72),
                      const _MerchantPartnerSection(),
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

class _MerchantPartnerSection extends StatelessWidget {
  const _MerchantPartnerSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Join as a partner',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manage your menu and track orders via\n'
          'the GiziGo Merchant Portal',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Sign up as Merchant',
          onPressed: () {
            context.pushNamed(AppRouter.registerMerchant);
          },
        ),
      ],
    );
  }
}
