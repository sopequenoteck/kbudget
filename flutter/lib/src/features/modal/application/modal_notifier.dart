import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/modal/application/modal_state.dart';

final modalNotifierProvider =
    NotifierProvider<ModalNotifier, ModalState>(ModalNotifier.new);

class ModalNotifier extends Notifier<ModalState> {
  @override
  ModalState build() => const ModalState.closed();

  void open(ModalType type, {Object? entity}) {
    // Garantir unicité : fermer si déjà ouverte
    if (state is ModalOpen) {
      state = const ModalState.closed();
    }

    final ModalMode mode;
    final dynamic subType;

    if (entity != null) {
      mode = ModalMode.edit;
      subType = _extractSubType(type, entity);
    } else {
      mode = ModalMode.create;
      subType = type.defaultSubType;
    }

    state = ModalState.open(
      type: type,
      mode: mode,
      entity: entity,
      subType: subType,
    );
  }

  void close() {
    state = const ModalState.closed();
  }

  void setSubType(dynamic value) {
    final current = state;
    if (current is ModalOpen) {
      state = ModalState.open(
        type: current.type,
        mode: current.mode,
        entity: current.entity,
        subType: value,
      );
    }
  }

  dynamic _extractSubType(ModalType type, Object entity) {
    return switch (type) {
      ModalType.transaction => (entity as Transaction).type,
      ModalType.subscription => (entity as Subscription).frequence,
      ModalType.debt => (entity as Debt).sens,
      _ => null,
    };
  }
}
