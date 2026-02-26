import 'package:k_budget/src/data/remote/data_sources/user_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/domain/repositories/user_repository.dart';
import 'package:k_budget/src/utils/enum_utils.dart';

class UserRepositoryRemote implements UserRepository {
  final UserRemoteDataSource _dataSource;

  UserRepositoryRemote(this._dataSource);

  @override
  Future<User> getProfile() async {
    final response = await _dataSource.getProfile();
    return _toDomain(response);
  }

  @override
  Future<User> updateProfile({required Currency defaultCurrency}) async {
    final request = UserUpdateRequest(
      defaultCurrency: defaultCurrency.name.toUpperCase(),
    );
    final response = await _dataSource.updateProfile(request);
    return _toDomain(response);
  }

  User _toDomain(UserResponse r) => User(
        id: 'profile',
        email: r.email,
        name: r.name,
        defaultCurrency: Currency.values
            .byNameOrDefault(r.defaultCurrency.toLowerCase(), Currency.eur),
      );
}
