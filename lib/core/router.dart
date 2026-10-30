import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../screens/auth_intro_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/app_shell.dart';
import '../features/play/screens/play_screen.dart';
import '../features/path/screens/path_screen.dart';
import '../features/ranks/screens/ranks_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/quiz/screens/quiz_screen.dart';
import 'widgets/design_system_preview.dart';

final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter({String initialLocation = '/play', bool enableAuthRedirect = true}) {
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: enableAuthRedirect ? GoRouterRefreshStream(AuthService.instance.authStateChanges) : null,
    redirect: enableAuthRedirect
        ? (BuildContext context, GoRouterState state) {
            final user = AuthService.instance.currentUser;
            final path = state.uri.path;

            final isAuthPath = path == '/auth-intro' || path == '/login' || path == '/splash';
            final isProfileSetup = path == '/profile-setup';
            final isPreview = path == '/design-preview';

            if (isPreview) return null;

            if (user == null) {
              return isAuthPath ? null : '/auth-intro';
            }

            if (!user.profileCompleted) {
              return isProfileSetup ? null : '/profile-setup';
            }

            if (isAuthPath || isProfileSetup) {
              return '/play';
            }

            return null;
          }
        : null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/play',
                builder: (context, state) => const PlayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/path',
                builder: (context, state) => const PathScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ranks',
                builder: (context, state) => const RanksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/quiz/:lobby',
        parentNavigatorKey: rootKey,
        builder: (context, state) => QuizScreen(
          lobby: state.pathParameters['lobby'] ?? 'noob',
        ),
      ),
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth-intro',
        parentNavigatorKey: rootKey,
        builder: (context, state) => AuthIntroScreen(onSuccess: () {}),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootKey,
        builder: (context, state) => LoginScreen(onSuccess: () {}),
      ),
      GoRoute(
        path: '/profile-setup',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const ProfileSetupScreen(mode: ProfileSetupMode.onboarding),
      ),
      GoRoute(
        path: '/design-preview',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const DesignSystemPreviewScreen(),
      ),
    ],
  );
}

final router = createRouter();
