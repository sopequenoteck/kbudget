// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/debt_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/debt_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/data/debt_repository_remote.dart';

/// Source de donnees factice : capture l'appel `repay` et renvoie une reponse
/// fixe (ou leve [error]), sans aucun appel reseau.
class _FakeDebtRemoteDataSource extends DebtRemoteDataSource {
  _FakeDebtRemoteDataSource(this.response, {this.error}) : super(Dio());

  final DebtResponse response;
  final Object? error;
  String? capturedId;
  RepayRequest? capturedRequest;
  int repayCalls = 0;

  @override
  Future<DebtResponse> repay(String id, RepayRequest request) async {
    repayCalls++;
    capturedId = id;
    capturedRequest = request;
    if (error != null) throw error!;
    return response;
  }
}

DebtResponse _debtResponse() => DebtResponse.fromJson(const {
  'id': 'debt-001',
  'personne': 'Jean',
  'montant': 50.0,
  'sens': 'PRET',
  'date': '2026-01-15T00:00:00',
  'currency': 'USD',
  'rembourse': false,
  'includeInBalance': true,
  'montantRestant': 20.0,
  'category': {'id': 'cat-001'},
  'account': {'id': 'acc-001', 'nom': 'Compte courant'},
  'updatedAt': '2026-02-01T10:00:00',
});

void main() {
  late _FakeDebtRemoteDataSource dataSource;
  late DebtRepositoryRemote repo;

  setUp(() {
    dataSource = _FakeDebtRemoteDataSource(_debtResponse());
    repo = DebtRepositoryRemote(dataSource);
  });

  group('DebtRepositoryRemote.repay', () {
    test('should_forwardIdAccountAmountAndLabel_when_labelProvided', () async {
      await repo.repay('debt-001', 'acc-001', 30.0, libelle: 'Remboursement');

      expect(dataSource.repayCalls, 1);
      expect(dataSource.capturedId, 'debt-001');
      expect(dataSource.capturedRequest!.accountId, 'acc-001');
      expect(dataSource.capturedRequest!.amount, 30.0);
      expect(dataSource.capturedRequest!.libelle, 'Remboursement');
    });

    test('should_forwardNullLabel_when_labelAbsent', () async {
      await repo.repay('debt-001', 'acc-001', 30.0);

      expect(dataSource.capturedRequest!.accountId, 'acc-001');
      expect(dataSource.capturedRequest!.amount, 30.0);
      expect(dataSource.capturedRequest!.libelle, isNull);
    });

    test('should_forwardNullAmount_when_repayingFully', () async {
      await repo.repay(
        'debt-001',
        'acc-001',
        null,
        libelle: 'Solde de la dette',
      );

      expect(dataSource.capturedRequest!.amount, isNull);
      expect(dataSource.capturedRequest!.libelle, 'Solde de la dette');
    });

    test('should_returnMappedDebt_when_dataSourceResponds', () async {
      final debt = await repo.repay('debt-001', 'acc-001', 30.0);

      expect(debt.id, 'debt-001');
      expect(debt.personne, 'Jean');
      expect(debt.montant, 50.0);
      expect(debt.sens, DebtType.pret);
      expect(debt.currency, Currency.usd);
      expect(debt.rembourse, isFalse);
      expect(debt.includeInBalance, isTrue);
      expect(debt.remainingAmount, 20.0);
      expect(debt.categoryId, 'cat-001');
      expect(debt.accountId, 'acc-001');
      expect(debt.accountName, 'Compte courant');
      expect(debt.date, DateTime.parse('2026-01-15T00:00:00'));
      expect(debt.updatedAt, DateTime.parse('2026-02-01T10:00:00'));
    });

    test('should_propagateError_when_dataSourceFails', () {
      final failingRepo = DebtRepositoryRemote(
        _FakeDebtRemoteDataSource(
          _debtResponse(),
          error: DioException(
            requestOptions: RequestOptions(path: '/debts/debt-001/repay'),
          ),
        ),
      );

      expect(
        failingRepo.repay('debt-001', 'acc-001', 30.0),
        throwsA(isA<DioException>()),
      );
    });
  });
}
