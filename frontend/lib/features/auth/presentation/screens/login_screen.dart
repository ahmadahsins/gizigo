import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

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
                      
                      // Email Field
                      const AuthTextField(
                        label: 'Email',
                        hintText: 'Enter your Email here',
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      AuthTextField(
                        label: 'Password',
                        hintText: 'Enter your Password here',
                        obscureText: _obscurePassword,
                        labelSuffix: GestureDetector(
                          onTap: () {},
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
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Sign in Button
                      PrimaryButton(
                        text: 'Sign in',
                        onPressed: () => context.goNamed('home'),
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
                        onPressed: () {},
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
