import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_state_changes.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_in_with_oauth.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/datasources/home_location_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/complete_activity.dart';
import '../../features/home/domain/usecases/create_activity.dart';
import '../../features/home/domain/usecases/get_activity_agenda.dart';
import '../../features/home/domain/usecases/get_activity_chat_messages.dart';
import '../../features/home/domain/usecases/get_activity_detail.dart';
import '../../features/home/domain/usecases/get_current_city_name.dart';
import '../../features/home/domain/usecases/get_current_location.dart';
import '../../features/home/domain/usecases/get_home_feed.dart';
import '../../features/home/domain/usecases/send_activity_chat_message.dart';
import '../../features/home/domain/usecases/set_activity_participation.dart';
import '../../features/home/domain/usecases/submit_activity_feedback.dart';
import '../../features/home/domain/usecases/watch_current_location.dart';
import '../../features/home/domain/usecases/watch_current_city_name.dart';
import '../../features/home/presentation/controllers/activity_chat_notice_controller.dart';
import '../../features/home/presentation/controllers/activity_chat_realtime_controller.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/profile/data/datasources/profile_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/create_profile.dart';
import '../../features/profile/domain/usecases/get_available_profile_interests.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/get_profile_activities.dart';
import '../../features/profile/domain/usecases/is_profile_onboarding_required.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_setup_bloc.dart';
import '../services/account_trust_service.dart';
import '../services/activity_attendance_service.dart';
import '../services/analytics_service.dart';
import '../services/safety_service.dart';
import '../utils/app_preferences.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();

  sl
    ..registerLazySingleton<SharedPreferences>(() => preferences)
    ..registerLazySingleton(() => AppPreferences(sl()))
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    ..registerLazySingleton<AnalyticsService>(() => AnalyticsService.instance)
    ..registerLazySingleton(() => AccountTrustService(sl(), sl()))
    ..registerLazySingleton(() => ActivityAttendanceService(sl()))
    ..registerLazySingleton(() => SafetyService(sl()))
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()))
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignInWithOAuth(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton(() => AuthStateChanges(sl()))
    ..registerFactory(() => AuthBloc(sl(), sl(), sl(), sl(), sl(), sl()))
    ..registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<HomeLocationDataSource>(
      () => const HomeLocationDataSourceImpl(),
    )
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(sl(), sl(), accountTrustService: sl()),
    )
    ..registerLazySingleton(() => ActivityChatRealtimeController(sl()))
    ..registerLazySingleton(() => ActivityChatNoticeController(sl(), sl()))
    ..registerLazySingleton(() => CreateActivity(sl()))
    ..registerLazySingleton(() => CompleteActivity(sl()))
    ..registerLazySingleton(() => GetActivityAgenda(sl()))
    ..registerLazySingleton(() => GetActivityChatMessages(sl()))
    ..registerLazySingleton(() => GetActivityDetail(sl()))
    ..registerLazySingleton(() => GetHomeFeed(sl()))
    ..registerLazySingleton(() => GetCurrentCityName(sl()))
    ..registerLazySingleton(() => GetCurrentLocation(sl()))
    ..registerLazySingleton(() => SendActivityChatMessage(sl()))
    ..registerLazySingleton(() => SetActivityParticipation(sl()))
    ..registerLazySingleton(() => SubmitActivityFeedback(sl()))
    ..registerLazySingleton(() => WatchCurrentCityName(sl()))
    ..registerLazySingleton(() => WatchCurrentLocation(sl()))
    ..registerFactory(() => HomeBloc(sl(), sl(), sl(), sl()))
    ..registerLazySingleton<ProfileDataSource>(
      () => ProfileRemoteDataSource(sl()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        sl(),
        accountTrustService: sl(),
        currentUserIdProvider: () => sl<SupabaseClient>().auth.currentUser?.id,
      ),
    )
    ..registerLazySingleton(() => CreateProfile(sl()))
    ..registerLazySingleton(() => GetAvailableProfileInterests(sl()))
    ..registerLazySingleton(() => GetProfile(sl()))
    ..registerLazySingleton(() => GetProfileActivities(sl()))
    ..registerLazySingleton(() => IsProfileOnboardingRequired(sl()))
    ..registerLazySingleton(() => UpdateProfile(sl()))
    ..registerFactory(() => ProfileBloc(sl(), sl()))
    ..registerFactory(() => ProfileSetupBloc(sl(), sl()));
}
