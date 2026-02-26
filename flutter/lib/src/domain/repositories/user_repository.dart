import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';

abstract class UserRepository {
  Future<User> getProfile();
  Future<User> updateProfile({required Currency defaultCurrency});
}
