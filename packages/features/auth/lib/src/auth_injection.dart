import 'package:get_it/get_it.dart';
import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';
import 'repositories/auth_repository.dart';
import 'bloc/auth_bloc.dart';

final sl = GetIt.instance;

void initAuthInjection() {
  // Try to register ApiClient if not already registered by core
  if (!sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ApiClient>(
      () => ApiClient(
        baseUrl: const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://expense-tracker-tw5r.onrender.com',
        ),
      ),
    );
  }

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: sl()),
  );

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl(), hiveService: sl<HiveService>()),
  );
}
