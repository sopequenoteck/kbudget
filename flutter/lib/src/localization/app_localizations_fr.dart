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
  String get errorsClientNetwork => 'Impossible de contacter le serveur';

  @override
  String get errorsClientUnknown => 'Erreur inattendue';

  @override
  String get errorsApiBadRequest => 'La demande n\'a pas pu être traitée.';

  @override
  String get errorsApiValidationError =>
      'Veuillez vérifier les informations saisies.';

  @override
  String get errorsApiMalformedRequest => 'Requête invalide.';

  @override
  String get errorsApiPasswordIncorrect => 'Mot de passe incorrect.';

  @override
  String get usersFeedbackCurrentPasswordIncorrect =>
      'Mot de passe actuel incorrect.';

  @override
  String get usersFeedbackLastAdminDeletionForbidden =>
      'Vous êtes le dernier administrateur. Veuillez nommer un autre administrateur avant de supprimer votre compte.';

  @override
  String get errorsApiPasswordUnchanged =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get errorsApiConfirmationRequired => 'Confirmation explicite requise.';

  @override
  String get errorsApiUnauthenticated => 'Authentification requise.';

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
  String get errorsApiPasswordResetRequired =>
      'Réinitialisation des identifiants requise';

  @override
  String get errorsApiPasswordResetNotRequired =>
      'La réinitialisation des identifiants n\'est pas requise pour ce compte.';

  @override
  String get errorsApiFeatureDisabled => 'Fonctionnalité désactivée';

  @override
  String get errorsApiLastAdminDeletionForbidden =>
      'Au moins un administrateur actif doit exister.';

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
  String get commonValidationRequired => 'Ce champ est requis.';

  @override
  String get commonValidationAmountPositive =>
      'Le montant doit être supérieur à 0';

  @override
  String commonValidationMaxLength(int max) {
    return '$max caractères maximum';
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

  @override
  String get authPageLoginTagline => 'Connectez-vous à votre compte';

  @override
  String get authFormEmailRequired => 'Email requis';

  @override
  String get authFormPasswordRequired => 'Mot de passe requis';

  @override
  String get authPageFirstLoginTitle => 'Premier accès';

  @override
  String get authPageFirstLoginNotice =>
      'Vous êtes connecté avec les identifiants initiaux générés par le système. Définissez dès maintenant votre email définitif, un mot de passe personnel et votre nom d\'affichage pour accéder à l\'application.';

  @override
  String get authFormDisplayNameRequired => 'Nom requis (100 caractères max)';

  @override
  String get authFeedbackResetError =>
      'Erreur lors de la mise à jour de vos identifiants. Veuillez réessayer.';

  @override
  String get authFormPasswordConfirmRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get authFeedbackInvalidLink =>
      'Lien invalide, expiré, déjà utilisé ou révoqué.';

  @override
  String get authFeedbackCreateAccountError =>
      'Erreur lors de la création du compte. Veuillez réessayer.';

  @override
  String get authFeedbackCheckingLink => 'Vérification du lien...';

  @override
  String get authPageInvalidLinkTitle => 'Lien invalide';

  @override
  String get authActionBackToLogin => 'Retour à la connexion';

  @override
  String get authPageAcceptInviteTitle => 'Créer votre compte';

  @override
  String get authPageAcceptInviteTagline =>
      'Quelques informations pour finaliser l\'inscription';

  @override
  String get authFormEmail => 'Email';

  @override
  String get authFormEmailInvalid => 'Email invalide';

  @override
  String get authFormPassword => 'Mot de passe';

  @override
  String get authFormDisplayName => 'Nom d\'affichage';

  @override
  String get authFormConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authFormPasswordMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get authFormCurrency => 'Devise';

  @override
  String get authActionCreateAccount => 'Créer mon compte';

  @override
  String get authActionSignIn => 'Se connecter';

  @override
  String authFormPasswordMinLength(int min) {
    return '$min caractères minimum';
  }

  @override
  String get authActionUnlockBiometricReason => 'Déverrouillez K-Budget';

  @override
  String get authFeedbackBiometricError =>
      'Erreur biométrique. Utilisez votre PIN.';

  @override
  String get authFormPinMinLength => 'Le PIN doit contenir au moins 4 chiffres';

  @override
  String get authFeedbackPinIncorrect => 'PIN incorrect';

  @override
  String get authDialogForgotPinTitle => 'PIN oublié ?';

  @override
  String get authDialogForgotPinServerMessage =>
      'Vous serez déconnecté et devrez vous reconnecter avec vos identifiants.';

  @override
  String get authDialogForgotPinLocalMessage =>
      'En mode local, la réinitialisation du PIN effacera toutes vos données. Cette action est irréversible.';

  @override
  String get authPagePinTagline => 'Saisissez votre PIN pour continuer';

  @override
  String get authActionUnlock => 'Déverrouiller';

  @override
  String get authActionBiometric => 'Biométrie';

  @override
  String get commonActionConfirm => 'Confirmer';

  @override
  String get commonActionClose => 'Fermer';

  @override
  String get commonActionChooseEmoji => 'Choisir un emoji';

  @override
  String get commonFormEmojiSearchPlaceholder => 'Rechercher un emoji...';

  @override
  String get commonEmptyNoRecentEmoji => 'Aucun emoji récent';

  @override
  String get transactionsActionCreate => 'Transaction';

  @override
  String get subscriptionsActionCreate => 'Abonnement';

  @override
  String get debtsActionCreate => 'Dette';

  @override
  String get budgetsActionCreate => 'Budget';

  @override
  String get transactionsActionTransfer => 'Virement';

  @override
  String get commonActionPreviousMonthAria => 'Mois précédent';

  @override
  String get commonActionNextMonthAria => 'Mois suivant';

  @override
  String get commonNavSettings => 'Paramètres';

  @override
  String get commonActionLogout => 'Déconnexion';

  @override
  String get commonActionReset => 'Réinitialiser';

  @override
  String get commonFormSearchPlaceholder => 'Rechercher...';

  @override
  String get commonFormSelectPlaceholder => 'Sélectionner...';

  @override
  String get commonEmptyNoResults => 'Aucun résultat';

  @override
  String categoriesActionCreateNamed(String name) {
    return 'Créer « $name »';
  }

  @override
  String get categoriesFormSearchPlaceholder => 'Rechercher une catégorie...';

  @override
  String get categoriesEmptyTitle => 'Aucune catégorie — créez-en une';

  @override
  String get categoriesActionCreate => 'Créer';

  @override
  String get categoriesListNoResults => 'Aucune catégorie trouvée';

  @override
  String get commonActionBack => 'Retour';

  @override
  String get accountsFormSelectBankPlaceholder => 'Sélectionner une banque';

  @override
  String get accountsFormBankTitle => 'Banque';

  @override
  String get accountsValueOtherCustom => 'Autre / Personnalisé';

  @override
  String get accountsFilterBankSearchPlaceholder => 'Rechercher une banque...';

  @override
  String get accountsFeedbackBanksLoadError =>
      'Impossible de charger les banques';

  @override
  String get accountsEmptyBankNotFound => 'Aucune banque trouvée';

  @override
  String get accountsListBankGroupFrance => 'France';

  @override
  String get accountsListBankGroupWestAfrica => 'Afrique de l\'Ouest';

  @override
  String get accountsListBankGroupInternational => 'International';

  @override
  String get commonFeedbackSaveError => 'Erreur lors de la sauvegarde';

  @override
  String get commonFeedbackDeleteError => 'Erreur lors de la suppression';

  @override
  String get commonFeedbackLoadError => 'Erreur de chargement';

  @override
  String get onboardingDialogSwitchToLocalTitle => 'Passer en mode local ?';

  @override
  String get onboardingDialogSwitchToLocalMessage =>
      'Vos données seront stockées uniquement sur cet appareil. Vous pourrez revenir en mode serveur depuis les paramètres.';

  @override
  String get onboardingActionUseLocalMode => 'Utiliser en mode local';

  @override
  String get onboardingPageTitle => 'Bienvenue sur K-Budget';

  @override
  String get onboardingPageTagline => 'Choisissez votre mode de données';

  @override
  String get onboardingValueLocalMode => 'Mode local';

  @override
  String get onboardingValueLocalModeHint =>
      'Vos données restent sur cet appareil';

  @override
  String get onboardingValueServerMode => 'Mode serveur';

  @override
  String get onboardingValueServerModeHint =>
      'Synchronisez avec votre serveur K-Budget';

  @override
  String get onboardingPageServerSetupTitle => 'Configuration serveur';

  @override
  String get onboardingFormServerUrlHint =>
      'Entrez l\'URL de votre serveur K-Budget';

  @override
  String get onboardingFormServerUrl => 'URL du serveur';

  @override
  String get onboardingFormServerUrlRequired => 'L\'URL est requise';

  @override
  String get onboardingFormServerUrlInvalid => 'URL invalide';

  @override
  String get onboardingFeedbackConnected => 'Connexion réussie';

  @override
  String get onboardingFeedbackConnecting => 'Connexion en cours...';

  @override
  String get onboardingActionCheckConnection => 'Vérifier la connexion';

  @override
  String get compatibilityPageClientTitle => 'Application à mettre à jour';

  @override
  String get compatibilityPageServerTitle => 'Serveur à mettre à jour';

  @override
  String get compatibilityPageTagline =>
      'Cette version de l\'application et votre serveur ne peuvent pas fonctionner ensemble.';

  @override
  String get compatibilityFeedbackOffline =>
      'Serveur injoignable. Vérifiez l\'URL et votre connexion.';

  @override
  String compatibilityFeedbackServerTooOldUnknown(String requiredVersion) {
    return 'Ce serveur est trop ancien pour indiquer sa version. Cette application requiert au minimum la version $requiredVersion. Mettez votre instance à jour, puis relancez l\'application.';
  }

  @override
  String compatibilityFeedbackServerTooOldVersion(
    String serverVersion,
    String requiredVersion,
  ) {
    return 'Ce serveur est en version $serverVersion. Cette application requiert au minimum la version $requiredVersion. Mettez votre instance à jour, puis relancez l\'application.';
  }

  @override
  String compatibilityFeedbackClientTooOld(String requiredVersion) {
    return 'Ce serveur exige au minimum la version $requiredVersion de l\'application. Mettez à jour K-Budget depuis votre magasin.';
  }

  @override
  String compatibilityFeedbackClientTooOldVerbose(
    String requiredVersion,
    String clientVersion,
  ) {
    return 'Ce serveur exige au minimum la version $requiredVersion de l\'application. Vous utilisez la version $clientVersion. Mettez à jour K-Budget depuis votre magasin.';
  }

  @override
  String get commonValueTomorrow => 'Demain';

  @override
  String commonValueDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'il y a $_temp0';
  }

  @override
  String commonValueWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '$count semaine',
    );
    return 'il y a $_temp0';
  }

  @override
  String commonValueDaysAgoShort(int count) {
    return 'il y a $count j.';
  }

  @override
  String commonValueInDaysShort(int count) {
    return 'dans $count j.';
  }

  @override
  String dashboardSummaryMonthVariation(String amount) {
    return '$amount ce mois';
  }
}
