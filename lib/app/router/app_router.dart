import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/domain/entities/home_activity.dart';
import '../../features/home/presentation/pages/activity_agenda_page.dart';
import '../../features/home/presentation/pages/activity_chat_page.dart';
import '../../features/home/presentation/pages/activity_chat_members_page.dart';
import '../../features/home/presentation/pages/activity_detail_page.dart';
import '../../features/home/presentation/pages/activity_join_confirmation_page.dart';
import '../../features/home/presentation/pages/activity_map_page.dart';
import '../../features/home/presentation/pages/activity_route_loader_page.dart';
import '../../features/home/presentation/pages/activity_search_page.dart';
import '../../features/home/presentation/pages/create_activity_page.dart';
import '../../features/home/presentation/pages/edit_activity_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/profile/presentation/pages/account_verification_page.dart';
import '../../features/profile/presentation/pages/app_info_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/account_gate.dart';
import '../../features/profile/presentation/pages/friends_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/premium_page.dart';
import '../../features/profile/presentation/pages/profile_completion_gate.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/profile/presentation/pages/privacy_location_page.dart';
import '../../core/utils/activity_deep_links.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const emailVerification = '/auth/email-verification';
  static const emailVerified = '/auth/email-verified';
  static const home = '/';
  static const createActivity = '/activities/create';
  static const activityDetail = '/activities/:activityId';
  static const editActivity = '/activities/:activityId/edit';
  static const activityJoinConfirmation = '/activities/:activityId/joined';
  static const activityChat = '/activities/:activityId/chat';
  static const activityChatMembers = '/activities/:activityId/chat/members';
  static const activityMessages = '/messages';
  static const activityAgenda = '/agenda';
  static const activityMap = '/map';
  static const search = '/search';
  static const profile = '/profile';
  static const friends = '/friends';
  static const appInfo = '/info';
  static const notifications = '/notifications';
  static const premium = '/premium';
  static const privacyLocation = '/privacy-location';
  static const accountVerification = '/account/verification';
  static const profileSetup = '/profile/setup';
  static const profileDetail = '/profile/:profileId';
  static const editProfile = '/profile/edit';
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  static String activityDetailPath(String activityId) =>
      '/activities/$activityId';

  static String editActivityPath(String activityId) =>
      '/activities/$activityId/edit';

  static String activityJoinConfirmationPath(String activityId) =>
      '/activities/$activityId/joined';

  static String activityChatPath(String activityId, {String? from}) {
    final path = '/activities/$activityId/chat';
    if (from == null || from.isEmpty) {
      return path;
    }
    return '$path?from=${Uri.encodeQueryComponent(from)}';
  }

  static String activityChatMembersPath(String activityId) =>
      '/activities/$activityId/chat/members';

  static String profilePath(String profileId) => '/profile/$profileId';

  static String emailVerificationPath(String email) {
    if (email.trim().isEmpty) {
      return emailVerification;
    }
    return '$emailVerification?email=${Uri.encodeQueryComponent(email)}';
  }
}

Widget _protectedShell(Widget child) {
  return AccountGate(child: ProfileCompletionGate(child: child));
}

Widget _phoneProtectedShell(Widget child) {
  return AccountGate(child: child);
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final activityDeepLinkRoute = activityRoutePathFromActivityDetailDeepLink(
        state.uri,
      );
      if (activityDeepLinkRoute != null &&
          state.uri.toString() != activityDeepLinkRoute) {
        return activityDeepLinkRoute;
      }

      final authState = authBloc.state;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isEmailVerificationRoute =
          state.matchedLocation == AppRoutes.emailVerification ||
          state.matchedLocation == AppRoutes.emailVerified;
      final isFtiRoute =
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding;

      if (authState is AuthAuthenticated &&
          (isAuthRoute || isFtiRoute) &&
          !isEmailVerificationRoute) {
        return AppRoutes.home;
      }

      if (authState is AuthUnauthenticated &&
          !isAuthRoute &&
          !isFtiRoute &&
          !isEmailVerificationRoute) {
        AccountGate.resetSessionCache();
        ProfileCompletionGate.resetSessionCache();
        return AppRoutes.splash;
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => _protectedShell(child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const HomePage());
            },
          ),
          GoRoute(
            path: AppRoutes.createActivity,
            builder: (context, state) {
              final args = state.extra;
              if (args is! CreateActivityPageArgs) {
                return const MissingCreateActivityPage();
              }
              return CreateActivityPage(
                location: args.location,
                categories: args.categories,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) {
              return const ActivitySearchPage();
            },
          ),
          GoRoute(
            path: AppRoutes.activityMessages,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const ActivityMessagesPage());
            },
          ),
          GoRoute(
            path: AppRoutes.activityAgenda,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const ActivityAgendaPage());
            },
          ),
          GoRoute(
            path: AppRoutes.activityMap,
            pageBuilder: (context, state) {
              final args = state.extra;
              if (args is! ActivityMapPageArgs) {
                return _noTransitionPage(state, const ActivityMapLoaderPage());
              }
              return _noTransitionPage(state, ActivityMapPage(args: args));
            },
          ),
          GoRoute(
            path: AppRoutes.activityChat,
            builder: (context, state) {
              final activity = state.extra;
              final from = state.uri.queryParameters['from'];
              final backFallbackRoute = from == 'joined'
                  ? AppRoutes.home
                  : null;
              if (activity is HomeActivity) {
                return ActivityChatPage(
                  activity: activity,
                  backFallbackRoute: backFallbackRoute,
                );
              }
              return ActivityRouteLoaderPage(
                activityId: state.pathParameters['activityId'] ?? '',
                target: ActivityRouteTarget.chat,
                backFallbackRoute: backFallbackRoute,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.activityChatMembers,
            builder: (context, state) {
              final activity = state.extra;
              if (activity is HomeActivity) {
                return ActivityChatMembersPage(activity: activity);
              }
              return ActivityRouteLoaderPage(
                activityId: state.pathParameters['activityId'] ?? '',
                target: ActivityRouteTarget.members,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.activityJoinConfirmation,
            builder: (context, state) {
              final activity = state.extra;
              if (activity is! HomeActivity) {
                return const MissingActivityDetailPage();
              }
              return ActivityJoinConfirmationPage(activity: activity);
            },
          ),
          GoRoute(
            path: AppRoutes.editActivity,
            builder: (context, state) {
              final activity = state.extra;
              if (activity is! HomeActivity) {
                return const MissingActivityDetailPage();
              }
              return EditActivityPage(activity: activity);
            },
          ),
          GoRoute(
            path: AppRoutes.activityDetail,
            builder: (context, state) {
              final activity = state.extra;
              if (activity is HomeActivity) {
                return ActivityDetailPage(activity: activity);
              }
              return ActivityRouteLoaderPage(
                activityId: state.pathParameters['activityId'] ?? '',
                target: ActivityRouteTarget.detail,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) {
              return _noTransitionPage(state, const ProfilePage());
            },
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) {
              return const FriendsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.appInfo,
            builder: (context, state) {
              return const AppInfoPage();
            },
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) {
              return const NotificationsPage();
            },
          ),
          GoRoute(
            path: AppRoutes.privacyLocation,
            builder: (context, state) {
              return const PrivacyLocationPage();
            },
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) {
              final profile = state.extra;
              if (profile is! Profile) {
                return const MissingEditProfilePage();
              }
              return EditProfilePage(profile: profile);
            },
          ),
          GoRoute(
            path: AppRoutes.profileDetail,
            builder: (context, state) {
              return ProfilePage(profileId: state.pathParameters['profileId']);
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => _phoneProtectedShell(child),
        routes: [
          GoRoute(
            path: AppRoutes.accountVerification,
            builder: (context, state) {
              return const AccountVerificationPage();
            },
          ),
          GoRoute(
            path: AppRoutes.premium,
            builder: (context, state) {
              return const PremiumPage();
            },
          ),
          GoRoute(
            path: AppRoutes.profileSetup,
            builder: (context, state) {
              return const ProfileSetupPage();
            },
          ),
        ],
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
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) {
          return EmailVerificationPage(
            mode: EmailVerificationPageMode.pending,
            email: state.uri.queryParameters['email'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.emailVerified,
        builder: (context, state) {
          return const EmailVerificationPage(
            mode: EmailVerificationPageMode.success,
          );
        },
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
