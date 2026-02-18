import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/account_dtos.dart';

class AccountRemoteDataSource {
  final Dio _dio;

  AccountRemoteDataSource(this._dio);

  Future<List<AccountResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/accounts');
    return response.data!
        .map((e) => AccountResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AccountResponse> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/accounts/$id');
    return AccountResponse.fromJson(response.data!);
  }

  Future<AccountResponse> create(AccountRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts',
      data: request.toJson(),
    );
    return AccountResponse.fromJson(response.data!);
  }

  Future<AccountResponse> update(
      String id, AccountRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/accounts/$id',
      data: request.toJson(),
    );
    return AccountResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/accounts/$id');
  }

  Future<AccountResponse> setDefault(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/accounts/$id/default',
    );
    return AccountResponse.fromJson(response.data!);
  }
}
