import 'package:flutter/material.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return AppRouter._build(ref, auth);
});

abstract final class AppRouter {
  static late GoRouter router;

  static void init(WidgetRef ref) {
    router = _build(ref, ref.read(authStateProvider));
  }

  static GoRouter _build(Ref ref, AsyncValue authState) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = authState.valueOrNull != null;
        final onAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation.startsWith('/onboarding');
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth && state.matchedLocation != '/onboarding') return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
            GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
            GoRoute(path: '/collaboration', builder: (_, __) => const CollaborationScreen()),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'account', builder: (_, __) => const SettingsScreen(tab: 'account')),
                GoRoute(path: 'connections', builder: (_, __) => const SettingsScreen(tab: 'connections')),
                GoRoute(path: 'billing', builder: (_, __) => const SettingsScreen(tab: 'billing')),
                GoRoute(path: 'security', builder: (_, __) => const SettingsScreen(tab: 'security')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
