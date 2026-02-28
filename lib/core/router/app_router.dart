import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/trips/screens/dashboard_screen.dart';
import '../../features/trips/screens/create_trip_screen.dart';
import '../../features/trips/screens/trip_detail_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Listen to auth state changes to trigger redirects
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Determine if user is authenticated based on Supabase session
      final isAuthenticated = authState.value?.session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) {
        // Force unauthenticated users to login
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        // Send authenticated users to the home dashboard
        return '/trips';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/trips'),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/trips/create',
        builder: (context, state) => const CreateTripScreen(),
      ),
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return TripDetailScreen(tripId: tripId);
        },
      ),
    ],
  );
}
