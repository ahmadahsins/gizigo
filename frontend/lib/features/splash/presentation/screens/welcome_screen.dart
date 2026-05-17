import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gizigo/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'image': 'assets/images/welcome-page-1.png',
      'title_1': 'Discover ',
      'title_green': 'Healthy',
      'title_2': ' Meals',
      'subtitle': 'Get personalized healthy food recommendations tailored to your needs, preferences, and daily lifestyle.',
      'bg_color': const Color(0xFFFAF1E6),
      'scale': 1.25,
    },
    {
      'image': 'assets/images/welcome-page-2.png',
      'title_1': 'Compare & Save',
      'title_green': '',
      'title_2': '',
      'subtitle': 'Easily compare prices across multiple delivery apps in one place and choose the most affordable option.',
      'bg_color': const Color(0xFFDEE3E8),
      'scale': 1.0,
    },
    {
      'image': 'assets/images/welcome-page-3.png',
      'title_1': 'Stay on Track',
      'title_green': '',
      'title_2': '',
      'subtitle': 'Track your daily healthy eating habits and build a consistent streak to support a better lifestyle over time.',
      'bg_color': const Color(0xFFDFF0F3),
      'scale': 1.25,
    },
  ];

  void _skip() {
    context.goNamed(AppRouter.login);
  }

  void _next() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.goNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double page = 0.0;
          if (_pageController.hasClients) {
            page = _pageController.page ?? 0.0;
          }
          
          Color? bgColor = _onboardingData[0]['bg_color'];
          if (page >= 0 && page < 1) {
            bgColor = Color.lerp(_onboardingData[0]['bg_color'], _onboardingData[1]['bg_color'], page);
          } else if (page >= 1 && page <= 2) {
            bgColor = Color.lerp(_onboardingData[1]['bg_color'], _onboardingData[2]['bg_color'], page - 1);
          }

          return Container(
            color: bgColor,
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
          children: [
            // Top Bar (Logo and Skip)
            Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/Logo - Green.png',
                      height: 28,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _currentPage < _onboardingData.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _currentPage == _onboardingData.length - 1,
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView for content
            Positioned.fill(
              top: 80,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Transform.scale(
                          scale: data['scale'] as double? ?? 1.0,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            data['image'] as String,
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(height: 160), 
                    ],
                  );
                },
              ),
            ),

            // Bottom White Sheet Container
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 320,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(200, 40),
                    topRight: Radius.elliptical(200, 40),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.heading2,
                        children: [
                          TextSpan(text: _onboardingData[_currentPage]['title_1']),
                          TextSpan(
                            text: _onboardingData[_currentPage]['title_green'],
                            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
                          ),
                          TextSpan(text: _onboardingData[_currentPage]['title_2']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      _onboardingData[_currentPage]['subtitle']!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
