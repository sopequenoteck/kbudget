// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/category_dtos.dart';

class CategoryRemoteDataSource {
  final Dio _dio;

  CategoryRemoteDataSource(this._dio);

  Future<List<CategoryResponse>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/categories');
    return response.data!
        .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryResponse> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/categories/$id');
    return CategoryResponse.fromJson(response.data!);
  }

  Future<CategoryResponse> create(CategoryRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: request.toJson(),
    );
    return CategoryResponse.fromJson(response.data!);
  }

  Future<CategoryResponse> update(
      String id, CategoryRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/categories/$id',
      data: request.toJson(),
    );
    return CategoryResponse.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/categories/$id');
  }
}
