import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/emergency/emergency_alert_screen.dart';
import '../features/potholes/potholes_map_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/ride_history/ride_history_screen.dart';
import '../features/ride_history/ride_detail_screen.dart';
import '../features/incidents/incident_history_screen.dart';
import '../features/settings/settings_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Wait until initial session check from local storage completes
      if (!authState.isSessionReady) {
        return null;
      }

      final isAuth = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password';

      // Redirect unauthenticated users to /login
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // Redirect already authenticated users away from auth screens
      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyAlertScreen(),
      ),
      GoRoute(
        path: '/potholes',
        builder: (context, state) => const PotholesMapScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: '/ride-detail',
        builder: (context, state) => RideDetailScreen(ride: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/incidents',
        builder: (context, state) => const IncidentHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

// Backward-compatible fallback router
final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyAlertScreen(),
    ),
    GoRoute(
      path: '/potholes',
      builder: (context, state) => const PotholesMapScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/ride-history',
      builder: (context, state) => const RideHistoryScreen(),
    ),
    GoRoute(
      path: '/ride-detail',
      builder: (context, state) => RideDetailScreen(ride: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/incidents',
      builder: (context, state) => const IncidentHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
