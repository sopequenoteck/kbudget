import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/recurring_transaction_dtos.dart';

class RecurringTransactionRemoteDataSource {
  final Dio _dio;

  RecurringTransactionRemoteDataSource(this._dio);

  Future<List<RecurringTransactionResponse>> getActive() async {
    final response = await _dio.get<List<dynamic>>('/transactions/recurring');
    return response.data!
        .map((e) => RecurringTransactionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> validate(String id) async {
    await _dio.post<void>('/transactions/recurring/$id/validate');
  }

  Future<RecurringTransactionResponse> skip(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/recurring/$id/skip',
    );
    return RecurringTransactionResponse.fromJson(response.data!);
  }

  Future<RecurringTransactionResponse> deactivate(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/recurring/$id/deactivate',
    );
    return RecurringTransactionResponse.fromJson(response.data!);
  }
}
