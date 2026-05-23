import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/auto_refresh_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase init skipped: $error');
  }

  runApp(const ProviderScope(child: GiziGoApp()));
}

class GiziGoApp extends StatefulWidget {
  const GiziGoApp({super.key});

  @override
  State<GiziGoApp> createState() => _GiziGoAppState();
}

class _GiziGoAppState extends State<GiziGoApp> {
  @override
  void initState() {
    super.initState();
    AutoRefreshService.instance.start();
  }

  @override
  void dispose() {
    AutoRefreshService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GiziGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Actions(
          actions: {
            EditableTextTapOutsideIntent:
                CallbackAction<EditableTextTapOutsideIntent>(
                  onInvoke: (intent) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    return null;
                  },
                ),
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
