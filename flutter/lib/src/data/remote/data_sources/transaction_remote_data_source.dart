import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/transaction_dtos.dart';

class TransactionRemoteDataSource {
  final Dio _dio;

  TransactionRemoteDataSource(this._dio);

  Future<List<TransactionResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/transactions');
    return response.data!
        .map((e) => TransactionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionResponse> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/transactions/$id');
    return TransactionResponse.fromJson(response.data!);
  }

  Future<TransactionResponse> create(TransactionRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: request.toJson(),
    );
    return TransactionResponse.fromJson(response.data!);
  }

  Future<TransactionResponse> update(
      String id, TransactionRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/transactions/$id',
      data: request.toJson(),
    );
    return TransactionResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/transactions/$id');
  }
}
