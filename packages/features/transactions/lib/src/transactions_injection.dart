import 'package:get_it/get_it.dart';
import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';
import 'repositories/transaction_repository.dart';
import 'bloc/transactions_bloc.dart';

final sl = GetIt.instance;

void initTransactionsInjection() {
  sl.registerLazySingleton(() => TransactionRepository(
    apiClient: sl<ApiClient>(),
    hiveService: sl<HiveService>(),
  ));

  sl.registerFactory(() => TransactionsBloc(
    transactionRepository: sl<TransactionRepository>(),
  ));
}
