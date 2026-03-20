import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/bank_remote_data_source.dart';
import 'package:k_budget/src/domain/models/bank.dart';
import 'package:k_budget/src/features/accounts/data/bank_repository_remote.dart';

final banksProvider = FutureProvider<List<Bank>>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  final repo = BankRepositoryRemote(BankRemoteDataSource(dio));
  return repo.getAll();
});
