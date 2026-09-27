// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonActionCancel => 'Annuler';

  @override
  String get commonActionSave => 'Enregistrer';

  @override
  String get commonActionDelete => 'Supprimer';

  @override
  String get commonActionEdit => 'Modifier';

  @override
  String get commonActionRetry => 'Réessayer';

  @override
  String get errorsClientGeneric => 'Une erreur est survenue';

  @override
  String get errorNetwork => 'Erreur de connexion réseau';

  @override
  String get errorsApiBadRequest => 'La demande n\'a pas pu être traitée.';

  @override
  String get errorsApiValidationError =>
      'Veuillez vérifier les informations saisies.';

  @override
  String get errorsApiMalformedRequest => 'Requête invalide.';

  @override
  String get errorCodePasswordIncorrect => 'Mot de passe incorrect';

  @override
  String get errorCodeCurrentPasswordIncorrect =>
      'Mot de passe actuel incorrect';

  @override
  String get errorCodePasswordUnchanged =>
      'Le nouveau mot de passe doit être différent de l\'actuel';

  @override
  String get errorsApiConfirmationRequired => 'Confirmation explicite requise.';

  @override
  String get errorCodeUnauthenticated => 'Authentification requise';

  @override
  String get errorsApiTokenExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get errorsApiTokenRevoked =>
      'Votre session a été révoquée. Veuillez vous reconnecter.';

  @override
  String get errorsApiTokenReuseDetected =>
      'Session interrompue par sécurité. Veuillez vous reconnecter.';

  @override
  String get errorsApiTokenInvalid =>
      'Session invalide. Veuillez vous reconnecter.';

  @override
  String get errorsApiAccessDenied => 'Accès refusé';

  @override
  String get errorCodePasswordResetRequired =>
      'Réinitialisation des identifiants requise';

  @override
  String get errorsApiPasswordResetNotRequired =>
      'La réinitialisation des identifiants n\'est pas requise pour ce compte.';

  @override
  String get errorsApiFeatureDisabled => 'Fonctionnalité désactivée';

  @override
  String get errorCodeLastAdminDeletionForbidden =>
      'Vous êtes le dernier administrateur. Veuillez nommer un autre administrateur avant de supprimer votre compte.';

  @override
  String get errorsApiNotFound => 'Ressource introuvable';

  @override
  String get errorsApiConflict => 'Conflit de données';

  @override
  String get errorsApiLastAdminCannotBeDisabled =>
      'Impossible de désactiver le dernier administrateur actif.';

  @override
  String get errorsApiEmailAlreadyExists => 'Email déjà utilisé';

  @override
  String get errorsApiTooManyRequests =>
      'Trop de tentatives. Réessayez dans quelques instants.';

  @override
  String get errorsApiInternalError => 'Une erreur interne est survenue';

  @override
  String get amount => 'Montant';

  @override
  String get currency => 'Devise';

  @override
  String get frequency => 'Fréquence';

  @override
  String get budgetsFormCategory => 'Catégorie';

  @override
  String get selectCategory => 'Sélectionner une catégorie';

  @override
  String get budgetsFormThresholdAria => 'Seuil d\'alerte';

  @override
  String get authFeedbackInvalidCredentials =>
      'Email ou mot de passe incorrect';

  @override
  String get transactionsEmptyMonth => 'Aucune transaction ce mois-ci';

  @override
  String get transactionsNoCategory => 'Sans catégorie';

  @override
  String get transactionsFormDescriptionPlaceholder => 'Libellé';

  @override
  String get transactionsFormAccount => 'Compte';

  @override
  String get transactionFormDeleteConfirmTitle => 'Supprimer la transaction';

  @override
  String get transactionFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.';

  @override
  String get subscriptionsFormNamePlaceholder => 'Nom';

  @override
  String get subscriptionsFormAccount => 'Compte';

  @override
  String get commonValueActive => 'Actif';

  @override
  String get subscriptionFormDeleteConfirmTitle => 'Supprimer l\'abonnement';

  @override
  String get subscriptionFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cet abonnement ? Cette action est irréversible.';

  @override
  String get subscriptionsEmptyTitle => 'Aucun abonnement';

  @override
  String get subscriptionsValuePerMonth => '/mois';

  @override
  String get subscriptionsValuePerYear => '/an';

  @override
  String subscriptionNextRenewal(String date) {
    return 'Prochain : $date';
  }

  @override
  String get commonValueInactive => 'Inactif';

  @override
  String get subscriptionsActionPay => 'Payer';

  @override
  String get subscriptionsFeedbackPaid => 'Paiement enregistré';

  @override
  String get subscriptionPaymentHistory => 'Historique des paiements';

  @override
  String get subscriptionNoPayments => 'Aucun paiement';

  @override
  String subscriptionPayments(int count) {
    return '$count paiements';
  }

  @override
  String get debtsFormPersonPlaceholder => 'Personne';

  @override
  String get debtFormDeleteConfirmTitle => 'Supprimer la dette';

  @override
  String get debtFormDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette dette ? Cette action est irréversible.';

  @override
  String get debtFormAccountPicker => 'Compte bancaire';

  @override
  String get debtsEmptyTitle => 'Aucune dette';

  @override
  String get debtsValueRepaid => 'Remboursé';

  @override
  String get debtDetailInitialAmount => 'Montant initial';

  @override
  String get debtDetailRemainingAmount => 'Montant restant';

  @override
  String get debtsActionRepay => 'Rembourser';

  @override
  String get debtsDialogSnoozeTitle => 'Reporter le rappel';

  @override
  String get debtDetailProgress => 'Progression';

  @override
  String get debtDetailDate => 'Date';

  @override
  String get debtDetailCurrency => 'Devise';

  @override
  String get debtsFormAccount => 'Compte';

  @override
  String get debtDetailAccountDeleted => 'Compte supprimé';

  @override
  String get debtDetailDueDate => 'Échéance';

  @override
  String get debtsFormCategory => 'Catégorie';

  @override
  String get debtDetailIncludedInBalance => 'Inclus dans le solde';

  @override
  String get debtsFormReminderAria => 'Rappel';

  @override
  String get debtsDetailPayments => 'Paiements';

  @override
  String get debtDetailTotalRepaid => 'Total remboursé';

  @override
  String get commonEmptyNoPayments => 'Aucun paiement enregistré';

  @override
  String get debtDetailPaymentsError =>
      'Erreur lors du chargement des paiements';

  @override
  String get debtsValueBorrowed => 'Emprunt';

  @override
  String get debtsValueLent => 'Prêt';

  @override
  String get repayAccountLabel => 'Compte source';

  @override
  String get debtsFormAccountPlaceholder => 'Sélectionner un compte';

  @override
  String get repayAccountRequired => 'Compte requis';

  @override
  String get repayAmountLabel => 'Montant';

  @override
  String get repayAmountRequired => 'Montant requis';

  @override
  String get debtsFeedbackAmountInvalid => 'Montant invalide';

  @override
  String repayAmountMax(String amount) {
    return 'Maximum: $amount';
  }

  @override
  String get repayNoAccounts =>
      'Aucun compte actif. Créez un compte dans les paramètres.';

  @override
  String get repaySuccess => 'Remboursement enregistré';

  @override
  String get debtsFeedbackRepayError => 'Erreur lors du remboursement';

  @override
  String get snoozeDateLabel => 'Nouvelle date';

  @override
  String get snoozeTimeLabel => 'Heure';

  @override
  String get snoozeDateFutureRequired => 'La date doit être dans le futur';

  @override
  String get debtsFeedbackSnoozed => 'Rappel reporté';

  @override
  String get snoozeError => 'Erreur lors du report';

  @override
  String get debtsActionSnooze => 'Reporter';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get transactionsFormTransferFromPlaceholder => 'Compte source';

  @override
  String get transactionsFormTransferToPlaceholder => 'Compte destination';

  @override
  String get transactionsFormAmount => 'Montant';

  @override
  String get transactionsFormNoteAria => 'Note';

  @override
  String get transferFormSaveButton => 'Valider';

  @override
  String get transactionsFormTransferAccountsMismatch =>
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
  String get accountsEmptyTitle => 'Aucun compte';

  @override
  String get accountsDialogCreateTitle => 'Nouveau compte';

  @override
  String get accountsDialogEditTitle => 'Modifier le compte';

  @override
  String get accountsValueCurrent => 'Courant';

  @override
  String get accountsValueSavings => 'Épargne';

  @override
  String get accountsValueCash => 'Espèces';

  @override
  String get accountsFormName => 'Nom du compte';

  @override
  String get accountsFormOpeningBalance => 'Solde initial';

  @override
  String get accountsFormCurrency => 'Devise';

  @override
  String get accountsFormIcon => 'Icône';

  @override
  String get commonFormColour => 'Couleur';

  @override
  String get accountFormActiveDefaultHint =>
      'Le compte par défaut ne peut pas être désactivé';

  @override
  String get accountsFormCurrentBalance => 'Solde actuel';

  @override
  String get accountsFormNewBalance => 'Nouveau solde';

  @override
  String get accountFormPreviewPlaceholder => 'Aperçu du compte';

  @override
  String get accountsValueDefault => 'Défaut';

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
  String get categoriesPageTitle => 'Catégories';

  @override
  String get categoriesEmptyNoCategories => 'Aucune catégorie';

  @override
  String get categoriesDialogCreateTitle => 'Nouvelle catégorie';

  @override
  String get categoriesDialogEditTitle => 'Modifier la catégorie';

  @override
  String get categoryFormNameField => 'Nom de la catégorie';

  @override
  String get categoryFormIconField => 'Icône';

  @override
  String get categoryNameRequired => 'Le nom est requis';

  @override
  String get categoryNameMaxLength => 'Maximum 30 caractères';

  @override
  String get categoryNameDuplicate => 'Ce nom de catégorie existe déjà';

  @override
  String get categoryEmojiRequired => 'L\'icône est requise';

  @override
  String get categoryDeleteConfirmTitle => 'Supprimer la catégorie';

  @override
  String get categoryDeleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette catégorie ? Les éléments liés seront dissociés.';

  @override
  String get categoryErrorLoad => 'Impossible de charger les catégories';

  @override
  String get categoryErrorCreate =>
      'Erreur lors de la création de la catégorie';

  @override
  String get categoryErrorUpdate =>
      'Erreur lors de la modification de la catégorie';

  @override
  String get categoryErrorDelete =>
      'Erreur lors de la suppression de la catégorie';

  @override
  String get emptyBudgetList => 'Aucun budget';

  @override
  String get deleteBudgetTitle => 'Supprimer le budget';

  @override
  String get deleteBudgetMessage =>
      'Êtes-vous sûr de vouloir supprimer ce budget ? Cette action est irréversible.';

  @override
  String get allCategoriesHaveBudgets =>
      'Toutes les catégories ont déjà un budget';

  @override
  String get total => 'Total';

  @override
  String get budgetOtherCategory => 'Autre';

  @override
  String get budgetActive => 'Budget actif';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notificationsActionMarkAllReadHint => 'Tout marquer lu';

  @override
  String get notificationsActionDeleteAllHint => 'Vider l\'historique';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationClearConfirmMessage =>
      'Supprimer toutes les notifications ? Cette action est irréversible.';

  @override
  String get debtsFeedbackLoadError => 'Impossible de charger la dette';

  @override
  String get commonValueToday => 'Aujourd\'hui';

  @override
  String get commonValueYesterday => 'Hier';

  @override
  String get recurringPageTitle => 'Récurrences';

  @override
  String get recurringValueOverdue => 'En retard';

  @override
  String get recurringValueUpcoming => 'À venir';

  @override
  String get recurringActionMarkAsPaid => 'Marquer comme payée';

  @override
  String get recurringActionSkipOccurrence => 'Passer cette occurrence';

  @override
  String get recurringActionDeactivate => 'Désactiver la récurrence';

  @override
  String get recurringActionPayAll => 'Tout payé';

  @override
  String recurringNextOccurrence(String date) {
    return 'Prochaine : $date';
  }

  @override
  String get recurringMonthlySummaryTitle => 'BILAN MENSUEL';

  @override
  String recurringChargesCount(int count) {
    return '$count CHARGES';
  }

  @override
  String get recurringEmpty => 'Aucune récurrence active';

  @override
  String get recurringFeedbackValidated => 'Transaction créée';

  @override
  String get recurringSkipSuccess => 'Échéance avancée';

  @override
  String get recurringFeedbackDeactivated => 'Récurrence désactivée';

  @override
  String get frequencyHebdomadaire => '/semaine';
}
