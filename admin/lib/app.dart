import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'data/providers/auth_provider.dart';

class SinaaAdminApp extends ConsumerStatefulWidget {
  const SinaaAdminApp({super.key});

  @override
  ConsumerState<SinaaAdminApp> createState() => _SinaaAdminAppState();
}

class _SinaaAdminAppState extends ConsumerState<SinaaAdminApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth on app start
    Future.microtask(() {
      ref.read(adminAuthStateProvider.notifier).initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(adminRouterProvider);
    final authState = ref.watch(adminAuthStateProvider);

    // Show loading while initializing
    if (!authState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text('جاري التحميل...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'صنعة - لوحة التحكم',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AdminTheme.lightTheme,
      darkTheme: AdminTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Localization
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Router
      routerConfig: router,
    );
  }
}
