import 'package:get_it/get_it.dart';
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
import '../../features/home/domain/usecases/create_activity.dart';
import '../../features/home/domain/usecases/get_current_city_name.dart';
import '../../features/home/domain/usecases/get_current_location.dart';
import '../../features/home/domain/usecases/get_home_feed.dart';
import '../../features/home/domain/usecases/watch_current_location.dart';
import '../../features/home/domain/usecases/watch_current_city_name.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
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
      () => HomeRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => CreateActivity(sl()))
    ..registerLazySingleton(() => GetHomeFeed(sl()))
    ..registerLazySingleton(() => GetCurrentCityName(sl()))
    ..registerLazySingleton(() => GetCurrentLocation(sl()))
    ..registerLazySingleton(() => WatchCurrentCityName(sl()))
    ..registerLazySingleton(() => WatchCurrentLocation(sl()))
    ..registerFactory(() => HomeBloc(sl(), sl(), sl()));
}
