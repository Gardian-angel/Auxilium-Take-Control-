import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/collaboration/screens/collaboration_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/billing/paywall_screen.dart';

/// One router for the app's lifetime. It re-runs [GoRouter.redirect] whenever
/// the Firebase auth state changes, instead of being rebuilt.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final refresh = _StreamListenable(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation.startsWith('/onboarding');
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth && state.matchedLocation != '/onboarding')
        return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(
              path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(
              path: '/collaboration',
              builder: (_, __) => const CollaborationScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                  path: 'account',
                  builder: (_, __) => const SettingsScreen(tab: 'account')),
              GoRoute(
                  path: 'connections',
                  builder: (_, __) => const SettingsScreen(tab: 'connections')),
              GoRoute(
                  path: 'billing',
                  builder: (_, __) => const SettingsScreen(tab: 'billing')),
              GoRoute(
                  path: 'security',
                  builder: (_, __) => const SettingsScreen(tab: 'security')),
            ],
          ),
        ],
      ),
    ],
  );
});

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
