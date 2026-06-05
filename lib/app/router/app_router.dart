import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/domain/entities/home_activity.dart';
import '../../features/home/presentation/pages/activity_detail_page.dart';
import '../../features/home/presentation/pages/create_activity_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_completion_gate.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const createActivity = '/activities/create';
  static const activityDetail = '/activities/:activityId';
  static const profile = '/profile';
  static const profileSetup = '/profile/setup';
  static const profileDetail = '/profile/:profileId';
  static const editProfile = '/profile/edit';
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  static String activityDetailPath(String activityId) =>
      '/activities/$activityId';

  static String profilePath(String profileId) => '/profile/$profileId';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isFtiRoute =
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding;

      if (authState is AuthAuthenticated && (isAuthRoute || isFtiRoute)) {
        return AppRoutes.home;
      }

      if (authState is AuthUnauthenticated && !isAuthRoute && !isFtiRoute) {
        return AppRoutes.splash;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          return const ProfileCompletionGate(child: HomePage());
        },
      ),
      GoRoute(
        path: AppRoutes.createActivity,
        builder: (context, state) {
          final args = state.extra;
          if (args is! CreateActivityPageArgs) {
            return const ProfileCompletionGate(
              child: MissingCreateActivityPage(),
            );
          }
          return ProfileCompletionGate(
            child: CreateActivityPage(
              location: args.location,
              categories: args.categories,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.activityDetail,
        builder: (context, state) {
          final activity = state.extra;
          if (activity is! HomeActivity) {
            return const ProfileCompletionGate(
              child: MissingActivityDetailPage(),
            );
          }
          return ProfileCompletionGate(
            child: ActivityDetailPage(activity: activity),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          return const ProfileCompletionGate(child: ProfilePage());
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          final profile = state.extra;
          if (profile is! Profile) {
            return const ProfileCompletionGate(child: MissingEditProfilePage());
          }
          return ProfileCompletionGate(
            child: EditProfilePage(profile: profile),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileDetail,
        builder: (context, state) {
          return ProfileCompletionGate(
            child: ProfilePage(profileId: state.pathParameters['profileId']),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
