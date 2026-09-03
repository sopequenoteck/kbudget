// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/bank_dtos.dart';

class BankRemoteDataSource {
  final Dio _dio;

  BankRemoteDataSource(this._dio);

  Future<List<BankResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/banks');
    return response.data!
        .map((e) => BankResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
