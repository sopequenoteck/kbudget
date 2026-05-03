import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/features/user_profile/data/user_profile_repository_remote.dart';
import 'package:k_budget/src/features/user_profile/domain/repositories/user_profile_repository.dart';

/// Provider server-only — pas de LocalRepository (RES-013).
final userProfileRepositoryProvider =
    FutureProvider<UserProfileRepository>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return UserProfileRepositoryRemote(dio);
});
