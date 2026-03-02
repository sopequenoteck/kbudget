import 'package:k_budget/src/domain/enums/enums.dart';

enum ModalType {
  transaction,
  subscription,
  debt,
  transfer,
  category,
  account,
  product,
}

enum ModalMode { create, edit }

/// Titres par type et mode
const Map<ModalType, String> modalCreateTitles = {
  ModalType.transaction: 'Nouvelle transaction',
  ModalType.subscription: 'Nouvel abonnement',
  ModalType.debt: 'Nouvelle dette',
  ModalType.transfer: 'Nouveau virement',
  ModalType.category: 'Nouvelle catégorie',
  ModalType.account: 'Nouveau compte',
  ModalType.product: 'Nouveau produit',
};

const Map<ModalType, String> modalEditTitles = {
  ModalType.transaction: 'Modifier la transaction',
  ModalType.subscription: "Modifier l'abonnement",
  ModalType.debt: 'Modifier la dette',
  ModalType.transfer: 'Modifier le virement',
  ModalType.category: 'Modifier la catégorie',
  ModalType.account: 'Modifier le compte',
  ModalType.product: 'Modifier le produit',
};

/// Sous-type par défaut en mode création (null = pas de toggle)
final Map<ModalType, dynamic> modalDefaultSubTypes = {
  ModalType.transaction: TransactionType.depense,
  ModalType.subscription: Frequency.mensuel,
  ModalType.debt: DebtType.emprunt,
  ModalType.transfer: null,
  ModalType.category: null,
  ModalType.account: null,
  ModalType.product: null,
};

/// Labels du toggle par type (null = pas de toggle)
const Map<ModalType, List<String>?> modalToggleLabels = {
  ModalType.transaction: ['Dépense', 'Recette'],
  ModalType.subscription: ['Mensuel', 'Annuel'],
  ModalType.debt: ['Emprunt', 'Prêt'],
  ModalType.transfer: null,
  ModalType.category: null,
  ModalType.account: null,
  ModalType.product: null,
};

/// Valeurs du toggle par type (ordre aligné avec les labels)
final Map<ModalType, List<dynamic>?> modalToggleValues = {
  ModalType.transaction: TransactionType.values,
  ModalType.subscription: Frequency.values,
  ModalType.debt: DebtType.values,
  ModalType.transfer: null,
  ModalType.category: null,
  ModalType.account: null,
  ModalType.product: null,
};

extension ModalTypeX on ModalType {
  String title(ModalMode mode) {
    return mode == ModalMode.create
        ? modalCreateTitles[this]!
        : modalEditTitles[this]!;
  }

  bool get hasToggle => modalToggleLabels[this] != null;

  List<String>? get toggleLabels => modalToggleLabels[this];

  List<dynamic>? get toggleValues => modalToggleValues[this];

  dynamic get defaultSubType => modalDefaultSubTypes[this];
}
