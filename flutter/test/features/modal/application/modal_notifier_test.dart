import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_state.dart';

void main() {
  late ProviderContainer container;
  late ModalNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(modalNotifierProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('ModalNotifier - create mode', () {
    test('should_beModalClosed_when_created', () {
      final state = container.read(modalNotifierProvider);
      expect(state, isA<ModalClosed>());
    });

    test('should_openTransaction_when_openCalledWithTransaction', () {
      notifier.open(ModalType.transaction);
      final state = container.read(modalNotifierProvider);
      expect(state, isA<ModalOpen>());
      final open = state as ModalOpen;
      expect(open.type, ModalType.transaction);
      expect(open.mode, ModalMode.create);
    });

    test('should_defaultToDepense_when_openTransactionInCreateMode', () {
      notifier.open(ModalType.transaction);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, TransactionType.depense);
    });

    test('should_defaultToMensuel_when_openSubscriptionInCreateMode', () {
      notifier.open(ModalType.subscription);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, Frequency.mensuel);
    });

    test('should_defaultToEmprunt_when_openDebtInCreateMode', () {
      notifier.open(ModalType.debt);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, DebtType.emprunt);
    });

    test('should_haveNullSubType_when_openTransfer', () {
      notifier.open(ModalType.transfer);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, isNull);
    });

    test('should_closePrevious_when_openCalledWhileAlreadyOpen', () {
      notifier.open(ModalType.transaction);
      notifier.open(ModalType.subscription);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.type, ModalType.subscription);
      expect(state.mode, ModalMode.create);
    });

    test('should_beModalClosed_when_closeCalled', () {
      notifier.open(ModalType.transaction);
      notifier.close();
      final state = container.read(modalNotifierProvider);
      expect(state, isA<ModalClosed>());
    });

    test('should_updateSubType_when_setSubTypeCalled', () {
      notifier.open(ModalType.transaction);
      notifier.setSubType(TransactionType.recette);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, TransactionType.recette);
    });
  });

  group('ModalNotifier - edit mode', () {
    test('should_setModeEdit_when_entityProvided', () {
      final tx = Transaction(
        id: '1',
        montant: 50,
        libelle: 'Test',
        type: TransactionType.recette,
        date: DateTime(2026),
      );
      notifier.open(ModalType.transaction, entity: tx);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.mode, ModalMode.edit);
      expect(state.entity, tx);
    });

    test('should_setModeCreate_when_entityNull', () {
      notifier.open(ModalType.transaction);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.mode, ModalMode.create);
      expect(state.entity, isNull);
    });

    test('should_extractRecette_when_editTransactionRecette', () {
      final tx = Transaction(
        id: '1',
        montant: 100,
        libelle: 'Salaire',
        type: TransactionType.recette,
        date: DateTime(2026),
      );
      notifier.open(ModalType.transaction, entity: tx);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, TransactionType.recette);
    });

    test('should_extractAnnuel_when_editSubscriptionAnnuel', () {
      final sub = Subscription(
        id: '1',
        nom: 'Netflix',
        montant: 120,
        frequence: Frequency.annuel,
        dateDebut: DateTime(2026),
      );
      notifier.open(ModalType.subscription, entity: sub);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, Frequency.annuel);
    });

    test('should_extractPret_when_editDebtPret', () {
      final debt = Debt(
        id: '1',
        personne: 'Alice',
        montant: 200,
        sens: DebtType.pret,
        date: DateTime(2026),
      );
      notifier.open(ModalType.debt, entity: debt);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(state.subType, DebtType.pret);
    });

    test('should_useEditTitle_when_modeIsEdit', () {
      final tx = Transaction(
        id: '1',
        montant: 50,
        libelle: 'Test',
        type: TransactionType.depense,
        date: DateTime(2026),
      );
      notifier.open(ModalType.transaction, entity: tx);
      final state = container.read(modalNotifierProvider) as ModalOpen;
      expect(
        state.type.title(state.mode),
        'Modifier la transaction',
      );
    });
  });
}
