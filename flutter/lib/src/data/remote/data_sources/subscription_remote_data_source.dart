// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/subscription_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/subscription_payment_dtos.dart';

class SubscriptionRemoteDataSource {
  final Dio _dio;

  SubscriptionRemoteDataSource(this._dio);

  Future<List<SubscriptionResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/subscriptions');
    return response.data!
        .map((e) => SubscriptionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionResponse> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/subscriptions/$id');
    return SubscriptionResponse.fromJson(response.data!);
  }

  Future<SubscriptionResponse> create(SubscriptionRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions',
      data: request.toJson(),
    );
    return SubscriptionResponse.fromJson(response.data!);
  }

  Future<SubscriptionResponse> update(
      String id, SubscriptionRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/subscriptions/$id',
      data: request.toJson(),
    );
    return SubscriptionResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/subscriptions/$id');
  }

  Future<SubscriptionPaymentResponse> pay(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions/$id/pay',
    );
    return SubscriptionPaymentResponse.fromJson(response.data!);
  }

  Future<List<SubscriptionPaymentResponse>> getPayments(String id) async {
    final response =
        await _dio.get<List<dynamic>>('/subscriptions/$id/payments');
    return response.data!
        .map((e) => SubscriptionPaymentResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionTotalPaidResponse> getTotalPaid(String id) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/subscriptions/$id/payments/total');
    return SubscriptionTotalPaidResponse.fromJson(response.data!);
  }
}
