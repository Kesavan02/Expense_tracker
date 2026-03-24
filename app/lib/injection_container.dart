import 'package:get_it/get_it.dart';
import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:local_storage/local_storage.dart';
import 'package:transactions/transactions.dart';
import 'package:budgeting/budgeting.dart';
import 'package:profile_settings/profile_settings.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Initialize Core Packages (e.g., ApiClient, LocalStorage)
  sl.registerLazySingleton(() => HiveService());

  // Initialize Feature Packages
  initAuthInjection();
  initTransactionsInjection();
  initBudgetingInjection();

  // Admin
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory<AdminBloc>(
    () => AdminBloc(adminRepository: sl<AdminRepository>()),
  );
}
