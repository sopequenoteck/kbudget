import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/debt_dtos.dart';

class DebtRemoteDataSource {
  final Dio _dio;

  DebtRemoteDataSource(this._dio);

  Future<List<DebtResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/debts');
    return response.data!
        .map((e) => DebtResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DebtResponse> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/debts/$id');
    return DebtResponse.fromJson(response.data!);
  }

  Future<DebtResponse> create(DebtRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/debts',
      data: request.toJson(),
    );
    return DebtResponse.fromJson(response.data!);
  }

  Future<DebtResponse> update(String id, DebtRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/debts/$id',
      data: request.toJson(),
    );
    return DebtResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/debts/$id');
  }
}
