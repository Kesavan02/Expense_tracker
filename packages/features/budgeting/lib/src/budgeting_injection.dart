import 'package:get_it/get_it.dart';
import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';
import 'repositories/budget_repository.dart';

final sl = GetIt.instance;

void initBudgetingInjection() {
  sl.registerLazySingleton(() => BudgetRepository(
    apiClient: sl<ApiClient>(),
    hiveService: sl<HiveService>(),
  ));
}
