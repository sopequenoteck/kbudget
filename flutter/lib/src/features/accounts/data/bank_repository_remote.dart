// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/data/remote/data_sources/bank_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/bank_dtos.dart';
import 'package:k_budget/src/domain/models/bank.dart';
import 'package:k_budget/src/domain/repositories/bank_repository.dart';

class BankRepositoryRemote implements BankRepository {
  final BankRemoteDataSource _dataSource;

  BankRepositoryRemote(this._dataSource);

  @override
  Future<List<Bank>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  Bank _toDomain(BankResponse r) => Bank(
        code: r.code,
        name: r.name,
        country: r.country,
        brandColor: r.brandColor,
        logoUrl: r.logoUrl,
      );
}
