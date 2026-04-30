import 'dart:io';

import 'package:dio/dio.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';
import 'package:k_budget/src/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:path_provider/path_provider.dart';

class UserProfileRepositoryRemote implements UserProfileRepository {
  final Dio _dio;

  /// Fonction retournant le répertoire de sauvegarde des exports.
  /// Injectée pour faciliter les tests sans appel platform channel.
  final Future<Directory> Function() _getExportDirectory;

  UserProfileRepositoryRemote(
    this._dio, {
    Future<Directory> Function()? getExportDirectory,
  }) : _getExportDirectory =
            getExportDirectory ?? getApplicationDocumentsDirectory;

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

  @override
  Future<File> exportJson() async {
    return _exportFile(format: 'json', fallbackExtension: 'json');
  }

  @override
  Future<File> exportCsv() async {
    return _exportFile(format: 'csv', fallbackExtension: 'csv');
  }

  Future<File> _exportFile({
    required String format,
    required String fallbackExtension,
  }) async {
    final response = await _dio.get<List<int>>(
      '/users/me/export',
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );

    final filename = _extractFilename(
      response.headers.value('content-disposition'),
      fallback:
          'kbudget-export-${DateTime.now().millisecondsSinceEpoch}.$fallbackExtension',
    );

    final dir = await _getExportDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(response.data!, flush: true);

    return file;
  }

  @override
  Future<void> deleteAccount(DeleteAccountRequest req) async {
    await _dio.delete<void>(
      '/users/me',
      data: req.toJson(),
    );
  }

  /// Extrait le filename depuis l'en-tête Content-Disposition.
  /// Format attendu : `attachment; filename="kbudget-export-xxx.json"`
  String _extractFilename(String? contentDisposition,
      {required String fallback}) {
    if (contentDisposition == null) return fallback;
    final match =
        RegExp(r'filename="?([^";\s]+)"?').firstMatch(contentDisposition);
    return match?.group(1) ?? fallback;
  }
}
