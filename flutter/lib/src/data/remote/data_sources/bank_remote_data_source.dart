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
