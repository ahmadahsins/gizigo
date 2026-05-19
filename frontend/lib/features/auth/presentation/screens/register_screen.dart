import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_dropdown_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  String? _selectedGender;

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
                      
                      // Full Name Field
                      const AuthTextField(
                        label: 'Full Name',
                        hintText: 'Enter your Full Name here',
                      ),
                      const SizedBox(height: 16),
                      
                      // Email Field
                      const AuthTextField(
                        label: 'Email',
                        hintText: 'Enter your Email here',
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      AuthTextField(
                        label: 'Password',
                        hintText: 'Enter your Password here',
                        obscureText: _obscurePassword,
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
                      const SizedBox(height: 16),
                      
                      // Gender & Age Row
                      Row(
                        children: [
                          Expanded(
                            child: AuthDropdownField(
                              label: 'Gender',
                              hintText: 'Select one',
                              items: const ['Male', 'Female'],
                              initialValue: _selectedGender,
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: AuthTextField(
                              label: 'Age',
                              hintText: 'Age (year)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Height & Weight Row
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: 'Height',
                              hintText: 'Height (cm)',
                              keyboardType: TextInputType.number,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                              keyboardType: TextInputType.number,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 32),
                      
                      // Sign up Button
                      PrimaryButton(
                        text: 'Sign up',
                        onPressed: () {},
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
                        onPressed: () {},
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
