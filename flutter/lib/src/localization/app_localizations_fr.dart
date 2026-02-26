// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'K-Budget';

  @override
  String get navDashboard => 'Accueil';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navSubscriptions => 'Abonnements';

  @override
  String get navDebts => 'Dettes';

  @override
  String get settings => 'Paramètres';

  @override
  String get themeLight => 'Thème clair';

  @override
  String get themeDark => 'Thème sombre';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get loading => 'Chargement...';

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get errorNetwork => 'Erreur de connexion réseau';

  @override
  String get errorServer => 'Erreur serveur';

  @override
  String get onboardingTitle => 'Bienvenue sur K-Budget';

  @override
  String get onboardingLocalTitle => 'Mode local';

  @override
  String get onboardingLocalDesc => 'Vos données restent sur cet appareil';

  @override
  String get onboardingServerTitle => 'Mode serveur';

  @override
  String get onboardingServerDesc => 'Synchronisez avec votre serveur K-Budget';

  @override
  String get onboardingChooseMode => 'Choisissez votre mode de données';

  @override
  String get serverUrlLabel => 'URL du serveur';

  @override
  String get serverUrlHint => 'https://budget.example.com/api';

  @override
  String get serverCheckConnection => 'Vérifier la connexion';

  @override
  String get serverConnecting => 'Connexion en cours...';

  @override
  String get serverConnected => 'Connexion réussie';

  @override
  String get serverUnreachable => 'Serveur injoignable';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get loginInvalidCredentials => 'Email ou mot de passe incorrect';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String get lockTitle => 'Déverrouillage';

  @override
  String get lockBiometric => 'Déverrouiller avec la biométrie';

  @override
  String get lockPin => 'Saisir le code PIN';

  @override
  String get fabNewTransaction => 'Nouvelle transaction';

  @override
  String get fabNewSubscription => 'Nouvel abonnement';

  @override
  String get fabNewDebt => 'Nouvelle dette';

  @override
  String get transactionsEmptyMonth => 'Aucune transaction ce mois-ci';

  @override
  String get transactionsEmptyDepenses => 'Aucune dépense ce mois-ci';

  @override
  String get transactionsEmptyRecettes => 'Aucune recette ce mois-ci';

  @override
  String get transactionsSummaryRecettes => 'Recettes';

  @override
  String get transactionsSummaryDepenses => 'Dépenses';

  @override
  String get transactionsSummaryBilan => 'Bilan';

  @override
  String get transactionsFilterAll => 'Tous';

  @override
  String get transactionsFilterDepenses => 'Dépenses';

  @override
  String get transactionsFilterRecettes => 'Recettes';

  @override
  String get transactionsRetry => 'Réessayer';

  @override
  String get transactionsNoCategory => 'Sans catégorie';

  @override
  String get transactionFormLabelField => 'Libellé';

  @override
  String get transactionFormAmountField => 'Montant';

  @override
  String get transactionFormDateField => 'Date';

  @override
  String get transactionFormNoteField => 'Note';

  @override
  String get transactionFormAccountPicker => 'Compte';

  @override
  String get transactionFormCategoryPicker => 'Catégorie';

  @override
  String get transactionFormSaveButton => 'Enregistrer';

  @override
  String get transactionFormUpdateButton => 'Modifier';

  @override
  String get transactionFormDeleteButton => 'Supprimer';

  @override
  String get transactionFormDeleteConfirmTitle => 'Supprimer la transaction';

  @override
  String get transactionFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.';

  @override
  String get transactionFormNoAccounts => 'Créez un compte dans les paramètres';

  @override
  String get transactionFormNoCategories => 'Créez une catégorie d\'abord';

  @override
  String get subscriptionFormNameField => 'Nom';

  @override
  String get subscriptionFormAmountField => 'Montant';

  @override
  String get subscriptionFormDateField => 'Date de début';

  @override
  String get subscriptionFormAccountPicker => 'Compte';

  @override
  String get subscriptionFormCategoryPicker => 'Catégorie';

  @override
  String get subscriptionFormActiveSwitch => 'Actif';

  @override
  String get subscriptionFormSaveButton => 'Enregistrer';

  @override
  String get subscriptionFormUpdateButton => 'Modifier';

  @override
  String get subscriptionFormDeleteButton => 'Supprimer';

  @override
  String get subscriptionFormDeleteConfirmTitle => 'Supprimer l\'abonnement';

  @override
  String get subscriptionFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cet abonnement ? Cette action est irréversible.';

  @override
  String get subscriptionFormNoAccounts =>
      'Créez un compte dans les paramètres';

  @override
  String get subscriptionFormNoCategories => 'Créez une catégorie d\'abord';

  @override
  String get subscriptionsEmpty => 'Aucun abonnement';

  @override
  String get subscriptionsRetry => 'Réessayer';

  @override
  String get subscriptionsFilterAll => 'Tous';

  @override
  String get subscriptionsFilterActifs => 'Actifs';

  @override
  String get subscriptionsFilterInactifs => 'Inactifs';

  @override
  String get subscriptionsTotalMensuel => 'Total mensuel';

  @override
  String get subscriptionsEmptyActifs => 'Aucun abonnement actif';

  @override
  String get subscriptionsEmptyInactifs => 'Aucun abonnement inactif';

  @override
  String get subscriptionFrequencyMensuel => '/mois';

  @override
  String get subscriptionFrequencyAnnuel => '/an';

  @override
  String subscriptionNextRenewal(String date) {
    return 'Prochain : $date';
  }

  @override
  String get subscriptionBadgeInactif => 'Inactif';

  @override
  String get debtFormPersonField => 'Personne';

  @override
  String get debtFormAmountField => 'Montant';

  @override
  String get debtFormDateField => 'Date';

  @override
  String get debtFormCategoryPicker => 'Catégorie';

  @override
  String get debtFormRepaidSwitch => 'Remboursé';

  @override
  String get debtFormSaveButton => 'Enregistrer';

  @override
  String get debtFormUpdateButton => 'Modifier';

  @override
  String get debtFormDeleteButton => 'Supprimer';

  @override
  String get debtFormDeleteConfirmTitle => 'Supprimer la dette';

  @override
  String get debtFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette dette ? Cette action est irréversible.';

  @override
  String get debtFormNoCategories => 'Créez une catégorie d\'abord';

  @override
  String get debtsTitle => 'Dettes';

  @override
  String get debtsSummaryEmprunts => 'Emprunts';

  @override
  String get debtsSummaryPrets => 'Prêts';

  @override
  String get debtsSummaryNet => 'Solde net';

  @override
  String get debtsFilterAll => 'Tous';

  @override
  String get debtsFilterEnCours => 'En cours';

  @override
  String get debtsFilterRembourse => 'Remboursé';

  @override
  String get debtsEmpty => 'Aucune dette';

  @override
  String get debtsEmptyEnCours => 'Aucune dette en cours';

  @override
  String get debtsEmptyRembourse => 'Aucune dette remboursée';

  @override
  String get debtsSectionPrets => 'Prêts';

  @override
  String get debtsSectionEmprunts => 'Emprunts';

  @override
  String get debtBadgeRembourse => 'Remboursé';

  @override
  String get transferFormSourcePicker => 'Compte source';

  @override
  String get transferFormDestinationPicker => 'Compte destination';

  @override
  String get transferFormAmountField => 'Montant';

  @override
  String get transferFormNoteField => 'Note';

  @override
  String get transferFormSaveButton => 'Valider';

  @override
  String get validationSameAccount =>
      'Les comptes source et destination doivent être différents';

  @override
  String get validationRequired => 'Champ requis';

  @override
  String get validationAmountPositive => 'Le montant doit être positif';

  @override
  String validationMaxLength(int max) {
    return 'Maximum $max caractères';
  }

  @override
  String get accountsTitle => 'Comptes';

  @override
  String get accountsEmpty => 'Aucun compte';

  @override
  String get accountsRetry => 'Réessayer';

  @override
  String get accountsNewTitle => 'Nouveau compte';

  @override
  String get accountsEditTitle => 'Modifier le compte';

  @override
  String get accountTypeCourant => 'Courant';

  @override
  String get accountTypeEpargne => 'Épargne';

  @override
  String get accountTypeEspeces => 'Espèces';

  @override
  String get accountFormNameField => 'Nom du compte';

  @override
  String get accountFormInitialBalanceField => 'Solde initial';

  @override
  String get accountFormCurrencyPicker => 'Devise';

  @override
  String get accountFormIconField => 'Icône';

  @override
  String get accountFormColorField => 'Couleur';

  @override
  String get accountFormActiveSwitch => 'Actif';

  @override
  String get accountFormActiveDefaultHint =>
      'Le compte par défaut ne peut pas être désactivé';

  @override
  String get accountFormCurrentBalance => 'Solde actuel';

  @override
  String get accountFormNewBalance => 'Nouveau solde';

  @override
  String get accountFormPreviewPlaceholder => 'Aperçu du compte';

  @override
  String get accountBadgeDefault => 'Défaut';

  @override
  String get accountBadgeInactive => 'Inactif';

  @override
  String get accountActionSetDefault => 'Définir par défaut';

  @override
  String get accountActionDelete => 'Supprimer';

  @override
  String get accountDeleteConfirmTitle => 'Supprimer le compte';

  @override
  String get accountDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer ce compte ? Cette action est irréversible.';

  @override
  String get accountErrorLoad => 'Impossible de charger les comptes';

  @override
  String get accountErrorCreate => 'Erreur lors de la création du compte';

  @override
  String get accountErrorUpdate => 'Erreur lors de la modification du compte';

  @override
  String get accountErrorDelete => 'Erreur lors de la suppression du compte';

  @override
  String get accountErrorSetDefault =>
      'Erreur lors du changement de compte par défaut';

  @override
  String get accountErrorAdjustBalance =>
      'Erreur lors de l\'ajustement du solde';
}
