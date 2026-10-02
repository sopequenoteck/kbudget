// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/account_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/account_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/adjust_balance_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/accounts/data/account_repository_remote.dart';

/// Source de donnees factice : capture l'appel `adjustBalance` et renvoie une
/// reponse fixe (ou leve [error]), sans aucun appel reseau.
class _FakeAccountRemoteDataSource extends AccountRemoteDataSource {
  _FakeAccountRemoteDataSource(this.response, {this.error}) : super(Dio());

  final AccountResponse response;
  final Object? error;
  String? capturedId;
  AdjustBalanceRequest? capturedRequest;
  int adjustBalanceCalls = 0;

  @override
  Future<AccountResponse> adjustBalance(
    String id,
    AdjustBalanceRequest request,
  ) async {
    adjustBalanceCalls++;
    capturedId = id;
    capturedRequest = request;
    if (error != null) throw error!;
    return response;
  }
}

AccountResponse _accountResponse() => AccountResponse.fromJson(const {
  'id': 'acc-001',
  'nom': 'Compte courant',
  'type': 'COURANT',
  'soldeInitial': 100.0,
  'icone': 'account_balance',
  'couleur': '#FFAA00',
  'isDefault': true,
  'currency': 'USD',
  'actif': true,
  'solde': 1500.5,
  'updatedAt': '2026-02-01T10:00:00',
});

void main() {
  late _FakeAccountRemoteDataSource dataSource;
  late AccountRepositoryRemote repo;

  setUp(() {
    dataSource = _FakeAccountRemoteDataSource(_accountResponse());
    repo = AccountRepositoryRemote(dataSource);
  });

  group('AccountRepositoryRemote.adjustBalance', () {
    test('should_forwardIdBalanceAndLabel_when_labelProvided', () async {
      await repo.adjustBalance(
        'acc-001',
        1500.5,
        libelle: 'Ajustement de solde',
      );

      expect(dataSource.adjustBalanceCalls, 1);
      expect(dataSource.capturedId, 'acc-001');
      expect(dataSource.capturedRequest!.newBalance, 1500.5);
      expect(dataSource.capturedRequest!.libelle, 'Ajustement de solde');
    });

    test('should_forwardNullLabel_when_labelAbsent', () async {
      await repo.adjustBalance('acc-001', 1500.5);

      expect(dataSource.capturedRequest!.newBalance, 1500.5);
      expect(dataSource.capturedRequest!.libelle, isNull);
    });

    test('should_forwardZeroBalance_when_balanceIsZero', () async {
      await repo.adjustBalance('acc-001', 0);

      expect(dataSource.capturedRequest!.newBalance, 0.0);
    });

    test('should_forwardNegativeBalance_when_balanceIsNegative', () async {
      await repo.adjustBalance('acc-001', -42.75, libelle: 'Decouvert');

      expect(dataSource.capturedRequest!.newBalance, -42.75);
      expect(dataSource.capturedRequest!.libelle, 'Decouvert');
    });

    test('should_returnMappedAccount_when_dataSourceResponds', () async {
      final account = await repo.adjustBalance('acc-001', 1500.5);

      expect(account.id, 'acc-001');
      expect(account.nom, 'Compte courant');
      expect(account.type, AccountType.courant);
      expect(account.currency, Currency.usd);
      expect(account.solde, 1500.5);
      expect(account.soldeInitial, 100.0);
      expect(account.isDefault, isTrue);
      expect(account.updatedAt, DateTime.parse('2026-02-01T10:00:00'));
    });

    test('should_propagateError_when_dataSourceFails', () {
      final failingRepo = AccountRepositoryRemote(
        _FakeAccountRemoteDataSource(
          _accountResponse(),
          error: DioException(
            requestOptions: RequestOptions(path: '/accounts/acc-001'),
          ),
        ),
      );

      expect(
        failingRepo.adjustBalance('acc-001', 10),
        throwsA(isA<DioException>()),
      );
    });
  });
}
