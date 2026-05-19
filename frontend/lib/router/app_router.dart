import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/splash/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/food/presentation/screens/food_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// App Router Configuration using go_router
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String search = 'search';
  static const String foodDetail = 'food-detail';
  static const String profile = 'profile';

  // Navigator keys
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome screen
      GoRoute(
        path: '/welcome',
        name: welcome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Login (no bottom nav)
      GoRoute(
        path: '/login',
        name: login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Register (no bottom nav)
      GoRoute(
        path: '/register',
        name: register,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Main app screens (no bottom nav)
      GoRoute(
        path: '/',
        name: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        name: search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      // Food detail (full screen, no bottom nav)
      GoRoute(
        path: '/food/:id',
        name: foodDetail,
        builder: (context, state) {
          final foodId = state.pathParameters['id']!;
          return FoodDetailScreen(foodId: foodId);
        },
      ),
    ],
  );
}
