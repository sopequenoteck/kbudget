import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/product_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/transaction_dtos.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource(this._dio);

  Future<List<ProductResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/products');
    return response.data!
        .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductResponse> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/products/$id');
    return ProductResponse.fromJson(response.data!);
  }

  Future<ProductResponse> create(ProductRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/products',
      data: request.toJson(),
    );
    return ProductResponse.fromJson(response.data!);
  }

  Future<ProductResponse> update(
      String id, ProductUpdateRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/products/$id',
      data: request.toJson(),
    );
    return ProductResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/products/$id');
  }

  Future<ProductResponse> sell(String id) async {
    final response = await _dio.post<Map<String, dynamic>>('/products/$id/sell');
    return ProductResponse.fromJson(response.data!);
  }

  Future<ProductResponse> restock(String id, RestockRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/products/$id/restock',
      data: request.toJson(),
    );
    return ProductResponse.fromJson(response.data!);
  }

  Future<List<TransactionResponse>> getSales(String id) async {
    final response = await _dio.get<List<dynamic>>('/products/$id/sales');
    return response.data!
        .map((e) => TransactionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
