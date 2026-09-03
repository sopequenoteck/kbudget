// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/exchange_rate_dtos.dart';

class ExchangeRateRemoteDataSource {
  final Dio _dio;

  ExchangeRateRemoteDataSource(this._dio);

  Future<List<ExchangeRateResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/exchange-rates');
    return response.data!
        .map((e) => ExchangeRateResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExchangeRateResponse> upsert(ExchangeRateRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/exchange-rates',
      data: request.toJson(),
    );
    return ExchangeRateResponse.fromJson(response.data!);
  }

  Future<void> delete(String baseCurrency, String targetCurrency) async {
    await _dio.delete<void>('/exchange-rates/$baseCurrency/$targetCurrency');
  }
}
