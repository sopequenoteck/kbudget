// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/features/admin/data/admin_repository.dart';
import 'package:k_budget/src/features/admin/data/admin_user_model.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

class AdminRemoteRepository implements AdminRepository {
  final Dio _dio;

  AdminRemoteRepository(this._dio);

  @override
  Future<InvitationCreated> createInvitation(String email) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/invitations',
      data: {'email': email},
    );
    return InvitationCreated.fromJson(response.data!);
  }

  @override
  Future<List<Invitation>> listInvitations() async {
    final response = await _dio.get<List<dynamic>>('/admin/invitations');
    return (response.data as List)
        .map((json) => Invitation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> revokeInvitation(int id) async {
    await _dio.delete<void>('/admin/invitations/$id');
  }

  @override
  Future<List<AdminUser>> listUsers() async {
    final response = await _dio.get<List<dynamic>>('/admin/users');
    return (response.data as List)
        .map((json) => AdminUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> disableUser(String id) async {
    await _dio.patch<void>('/admin/users/$id/disable');
  }

  @override
  Future<void> enableUser(String id) async {
    await _dio.patch<void>('/admin/users/$id/enable');
  }
}

final adminRepositoryProvider = FutureProvider<AdminRepository>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return AdminRemoteRepository(dio);
});
