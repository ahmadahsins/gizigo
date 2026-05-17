import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/splash/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/food/presentation/screens/food_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'package:gizigo/core/widgets/main_scaffold.dart';

/// App Router Configuration using go_router
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String home = 'home';
  static const String search = 'search';
  static const String foodDetail = 'food-detail';
  static const String profile = 'profile';

  // Navigator keys
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Login (no bottom nav)
      GoRoute(
        path: '/login',
        name: login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
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
        ],
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
