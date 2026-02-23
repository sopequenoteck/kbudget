import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/domain/repositories/user_repository.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_providers.dart';

final userProfileNotifierProvider =
    AsyncNotifierProvider<UserProfileNotifier, User>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<User> {
  UserRepository get _repo => ref.read(userRepositoryProvider).requireValue;

  @override
  Future<User> build() async {
    final repo = await ref.watch(userRepositoryProvider.future);
    return repo.getProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getProfile());
  }

  Future<bool> updateCurrency(Currency currency) async {
    final previous = state.valueOrNull;
    if (previous == null) return false;

    state = AsyncData(previous.copyWith(defaultCurrency: currency));

    try {
      final updated = await _repo.updateProfile(defaultCurrency: currency);
      state = AsyncData(updated);
      return true;
    } on Exception {
      state = AsyncData(previous);
      return false;
    }
  }
}
