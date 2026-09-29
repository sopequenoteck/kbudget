// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/category_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/category_dtos.dart';
import 'package:k_budget/src/features/categories/data/category_repository_remote.dart';

/// Source de donnees factice : renvoie des reponses fixes, sans reseau.
class _FakeCategoryRemoteDataSource extends CategoryRemoteDataSource {
  _FakeCategoryRemoteDataSource(this.responses) : super(Dio());

  final List<CategoryResponse> responses;

  @override
  Future<List<CategoryResponse>> getAll() async => responses;

  @override
  Future<CategoryResponse> getById(String id) async =>
      responses.firstWhere((r) => r.id == id);
}

const _system = CategoryResponse(
  id: 'cat-sys',
  nom: 'Subscription',
  icone: '🔁',
  couleur: '#8B5CF6',
  isSystem: true,
  systemKey: 'SUBSCRIPTION',
);

const _user = CategoryResponse(
  id: 'cat-usr',
  nom: 'Courses',
  icone: '🛒',
  couleur: '#10B981',
  isSystem: false,
);

void main() {
  late CategoryRepositoryRemote repo;

  setUp(() {
    repo = CategoryRepositoryRemote(
      _FakeCategoryRemoteDataSource([_system, _user]),
    );
  });

  group('CategoryRepositoryRemote mapping', () {
    test('should_carrySystemKey_when_categoryIsSystem', () async {
      final categories = await repo.getAll();

      expect(categories.first.systemKey, 'SUBSCRIPTION');
      expect(categories.first.nom, 'Subscription');
    });

    test('should_leaveSystemKeyNull_when_categoryIsUser', () async {
      final category = await repo.getById('cat-usr');

      expect(category.systemKey, isNull);
      expect(category.nom, 'Courses');
    });
  });
}
