import 'dart:io';

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:k_budget/src/features/user_profile/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryRemote implements UserProfileRepository {
  final Dio _dio;

  UserProfileRepositoryRemote(this._dio);

  @override
  Future<AvatarMetadata> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/me/avatar',
      data: formData,
    );
    return AvatarMetadata.fromJson(response.data!);
  }

  @override
  Future<void> deleteAvatar() async {
    await _dio.delete<void>('/users/me/avatar');
  }

  @override
  Future<AuthResponse> changePassword(ChangePasswordRequest req) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/me/password',
      data: req.toJson(),
    );
    return AuthResponse.fromJson(response.data!);
  }

  @override
  Future<void> updateName(String name) async {
    await _dio.put<void>(
      '/users/me',
      data: {'name': name},
    );
  }
}
