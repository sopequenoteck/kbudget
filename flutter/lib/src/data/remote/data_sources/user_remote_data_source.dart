import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/user_dtos.dart';

class UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSource(this._dio);

  Future<UserResponse> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserResponse.fromJson(response.data!);
  }

  Future<UserResponse> updateProfile(UserUpdateRequest request) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me',
      data: request.toJson(),
    );
    return UserResponse.fromJson(response.data!);
  }
}
