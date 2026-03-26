library;

export 'src/ui/budget_screen.dart';
export 'src/bloc/budget_bloc.dart';
export 'src/bloc/budget_event.dart';
export 'src/bloc/budget_state.dart';
export 'src/models/budget_model.dart';
export 'src/repositories/budget_repository.dart';

import 'package:get_it/get_it.dart';
import 'src/repositories/budget_repository.dart';
import 'src/bloc/budget_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';

void initBudgetingInjection() {
  final sl = GetIt.instance;

  // Repository
  if (!sl.isRegistered<BudgetRepository>()) {
    sl.registerLazySingleton<BudgetRepository>(
      () => BudgetRepository(
        apiClient: sl<ApiClient>(),
        hiveService: sl<HiveService>(),
      ),
    );
  }

  // Bloc
  if (!sl.isRegistered<BudgetBloc>()) {
    sl.registerFactory<BudgetBloc>(
      () => BudgetBloc(budgetRepository: sl<BudgetRepository>()),
    );
  }
}
