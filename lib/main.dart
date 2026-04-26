import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen while the app initializes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('INIT ERROR: $e');
  }

  // Remove the native splash screen to allow the Flutter UI (like the SplashLoadingScreen) to show
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: TripTrackApp()));
}

class TripTrackApp extends ConsumerWidget {
  const TripTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TripTrack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
