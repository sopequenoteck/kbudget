import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/user_remote_data_source.dart';
import 'package:k_budget/src/domain/repositories/user_repository.dart';
import 'package:k_budget/src/features/user_profile/data/user_repository_remote.dart';

final userRemoteDataSourceProvider =
    FutureProvider<UserRemoteDataSource>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return UserRemoteDataSource(dio);
});

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final dataSource = await ref.watch(userRemoteDataSourceProvider.future);
  return UserRepositoryRemote(dataSource);
});
