import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/budget_dtos.dart';

class BudgetRemoteDataSource {
  final Dio _dio;

  BudgetRemoteDataSource(this._dio);

  Future<List<BudgetResponse>> getAll({bool includeInactive = false}) async {
    final response = await _dio.get<List<dynamic>>(
      '/budgets',
      queryParameters: {'includeInactive': includeInactive},
    );
    return response.data!
        .map((e) => BudgetResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetResponse> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/budgets/$id');
    return BudgetResponse.fromJson(response.data!);
  }

  Future<BudgetResponse> create(BudgetRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/budgets',
      data: request.toJson(),
    );
    return BudgetResponse.fromJson(response.data!);
  }

  Future<BudgetResponse> update(String id, BudgetRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/budgets/$id',
      data: request.toJson(),
    );
    return BudgetResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/budgets/$id');
  }

  Future<BudgetOverviewResponse> getOverview() async {
    final response = await _dio.get<Map<String, dynamic>>('/budgets/overview');
    return BudgetOverviewResponse.fromJson(response.data!);
  }

  Future<BudgetHistoryResponse> getHistory(String month) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/budgets/history',
      queryParameters: {'month': month},
    );
    return BudgetHistoryResponse.fromJson(response.data!);
  }
}
