// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';

abstract class UserRepository {
  Future<User> getProfile();
  Future<User> updateProfile({required Currency defaultCurrency});
}
