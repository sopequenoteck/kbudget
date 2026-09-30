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
  String get budgetsFormAmount => 'Montant';

  @override
  String get budgetsFormCurrencyAria => 'Devise';

  @override
  String get budgetsFormFrequencyAria => 'Fréquence';

  @override
  String get budgetsFormCategory => 'Catégorie';

  @override
  String get budgetsFormCategoryPlaceholder => 'Choisir une catégorie';

  @override
  String get budgetsFormThresholdAria => 'Seuil d\'alerte';

  @override
  String get authFeedbackInvalidCredentials =>
      'Email ou mot de passe incorrect';

  @override
  String transactionsEmptyNoneInMonth(String month) {
    return 'Aucune transaction en $month';
  }

  @override
  String get transactionsListNoCategory => 'Sans catégorie';

  @override
  String get transactionsFormDescriptionPlaceholder => 'Libellé';

  @override
  String get transactionsFormAccount => 'Compte';

  @override
  String get transactionsDialogDeleteTitle => 'Supprimer la transaction';

  @override
  String get transactionsDialogDeleteMessage =>
      'Voulez-vous vraiment supprimer cette transaction ?';

  @override
  String get subscriptionsFormNamePlaceholder => 'Nom';

  @override
  String get subscriptionsFormAccount => 'Compte';

  @override
  String get commonValueActive => 'Actif';

  @override
  String get subscriptionsDialogDeleteTitle => 'Supprimer l\'abonnement';

  @override
  String get subscriptionsDialogDeleteMessage =>
      'Voulez-vous vraiment supprimer cet abonnement ?';

  @override
  String get subscriptionsEmptyTitle => 'Aucun abonnement';

  @override
  String get subscriptionsValuePerMonth => '/mois';

  @override
  String get subscriptionsValuePerYear => '/an';

  @override
  String subscriptionsListNextRenewal(String date) {
    return 'Prochain : $date';
  }

  @override
  String get commonValueInactive => 'Inactif';

  @override
  String get subscriptionsActionPay => 'Payer';

  @override
  String get subscriptionsFeedbackPaid => 'Paiement enregistré';

  @override
  String get subscriptionsDetailHistory => 'Historique';

  @override
  String subscriptionsDetailPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements',
      one: '$count paiement',
    );
    return '$_temp0';
  }

  @override
  String get debtsFormPersonPlaceholder => 'Personne';

  @override
  String get debtsDialogDeleteFormTitle => 'Supprimer la dette';

  @override
  String get debtsDialogDeleteFormMessage =>
      'Voulez-vous vraiment supprimer cette dette ?';

  @override
  String get debtsEmptyTitle => 'Aucune dette';

  @override
  String get debtsValueRepaid => 'Remboursé';

  @override
  String get debtsDetailInitialAmount => 'Montant initial';

  @override
  String get debtsDetailRemainingAmount => 'Montant restant';

  @override
  String get debtsActionRepay => 'Rembourser';

  @override
  String get debtsDialogSnoozeTitle => 'Reporter le rappel';

  @override
  String get debtsDetailProgress => 'Progression';

  @override
  String get debtsDetailDate => 'Date';

  @override
  String get debtsFormCurrency => 'Devise';

  @override
  String get debtsFormAccount => 'Compte';

  @override
  String get debtsDetailAccountDeleted => 'Compte supprimé';

  @override
  String get debtsFormDueDate => 'Échéance';

  @override
  String get debtsFormCategory => 'Catégorie';

  @override
  String get debtsDetailIncludedInBalance => 'Inclus dans le solde';

  @override
  String get debtsFormReminderAria => 'Rappel';

  @override
  String get debtsDetailPayments => 'Paiements';

  @override
  String get debtsDetailTotalRepaid => 'Total remboursé';

  @override
  String get commonEmptyNoPayments => 'Aucun paiement enregistré';

  @override
  String get debtsFeedbackPaymentsLoadError =>
      'Erreur lors du chargement des paiements';

  @override
  String get debtsValueBorrowed => 'Emprunt';

  @override
  String get debtsValueLent => 'Prêt';

  @override
  String get debtsFormAccountPlaceholder => 'Sélectionner un compte';

  @override
  String get debtsFormAccountRequired => 'Compte requis';

  @override
  String get debtsFormAmount => 'Montant';

  @override
  String get debtsFormAmountRequired => 'Montant requis';

  @override
  String get debtsFeedbackAmountInvalid => 'Montant invalide';

  @override
  String debtsFormAmountMax(String amount) {
    return 'Maximum : $amount';
  }

  @override
  String get debtsEmptyNoAccounts =>
      'Aucun compte actif. Créez un compte dans les paramètres.';

  @override
  String get debtsFeedbackRepaymentSaved => 'Remboursement enregistré';

  @override
  String get debtsFeedbackRepayError => 'Erreur lors du remboursement';

  @override
  String get debtsFormReminderDate => 'Date du rappel';

  @override
  String get debtsFormReminderTime => 'Heure du rappel';

  @override
  String get debtsDialogReminderDatePast =>
      'La date ne peut pas être dans le passé';

  @override
  String get debtsFeedbackSnoozed => 'Rappel reporté';

  @override
  String get debtsFeedbackSnoozeError => 'Erreur lors du report du rappel';

  @override
  String get debtsActionSnooze => 'Reporter';

  @override
  String get commonValueYes => 'Oui';

  @override
  String get commonValueNo => 'Non';

  @override
  String get transactionsFormTransferFromPlaceholder => 'Compte source';

  @override
  String get transactionsFormTransferToPlaceholder => 'Compte destination';

  @override
  String get transactionsFormAmount => 'Montant';

  @override
  String get transactionsFormNoteAria => 'Note';

  @override
  String get transactionsActionTransferSubmit => 'Effectuer le virement';

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
  String get accountsPageTitle => 'Comptes';

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
  String get accountsFormActiveHint =>
      'Définissez un autre compte par défaut avant de désactiver celui-ci';

  @override
  String get accountsFormCurrentBalance => 'Solde actuel';

  @override
  String get accountsFormNewBalance => 'Nouveau solde';

  @override
  String get accountsFormPreviewPlaceholder => 'Aperçu du compte';

  @override
  String get accountsValueDefault => 'Défaut';

  @override
  String get accountsDialogDeleteTitle => 'Supprimer le compte';

  @override
  String get accountsDialogDeleteWarningMessage =>
      'Êtes-vous sûr de vouloir supprimer ce compte ? Cette action est irréversible.';

  @override
  String get accountsFeedbackLoadError => 'Erreur de chargement des comptes';

  @override
  String get categoriesPageTitle => 'Catégories';

  @override
  String get categoriesEmptyNoCategories => 'Aucune catégorie';

  @override
  String get categoriesDialogCreateTitle => 'Nouvelle catégorie';

  @override
  String get categoriesDialogEditTitle => 'Modifier la catégorie';

  @override
  String get categoriesFormName => 'Nom';

  @override
  String get categoriesFormIcon => 'Icône';

  @override
  String get commonValidationNameRequired => 'Nom requis';

  @override
  String get categoriesFormNameMaxLength => '30 caractères maximum';

  @override
  String get categoriesFormNameDuplicate => 'Ce nom de catégorie existe déjà';

  @override
  String get categoriesFormIconRequired => 'L\'icône est requise';

  @override
  String get categoriesDialogDeleteTitle => 'Supprimer la catégorie';

  @override
  String get categoriesDialogDeleteMessage =>
      'Cette catégorie sera dissociée de tous les items liés.';

  @override
  String get budgetsEmptyTitle => 'Aucun budget pour cette période';

  @override
  String get budgetsDialogDeleteTitle => 'Supprimer le budget';

  @override
  String get budgetsDialogDeleteMessage =>
      'Voulez-vous vraiment supprimer ce budget ?';

  @override
  String get budgetsEmptyAllCategoriesBudgeted =>
      'Toutes les catégories ont déjà un budget.';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notificationsActionMarkAllReadHint => 'Tout marquer lu';

  @override
  String get notificationsActionDeleteAllHint => 'Vider l\'historique';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsDialogDeleteAllMessage =>
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
  String recurringDetailNext(String date) {
    return 'Prochaine : $date';
  }

  @override
  String get recurringSummaryTitle => 'Bilan mensuel';

  @override
  String recurringSummaryExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges',
      one: '$count charge',
    );
    return '$_temp0';
  }

  @override
  String get recurringEmptyTitle => 'Aucune transaction récurrente';

  @override
  String get recurringFeedbackValidatedOne => 'Transaction validée';

  @override
  String get recurringFeedbackSkipped => 'Occurrence passée';

  @override
  String get recurringFeedbackDeactivated => 'Récurrence désactivée';

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

  @override
  String get transactionsPageTitle => 'Transactions';

  @override
  String get transactionsListThisWeek => 'Cette semaine';

  @override
  String get transactionsListLastWeek => 'Semaine dernière';

  @override
  String get transactionsListOlder => 'Plus ancien';

  @override
  String get transactionsSummaryBalance => 'Solde';

  @override
  String get transactionsDialogCreateTitle => 'Nouvelle transaction';

  @override
  String get transactionsDialogEditTitle => 'Modifier la transaction';

  @override
  String get transactionsValueExpense => 'Dépense';

  @override
  String get transactionsValueIncome => 'Recette';

  @override
  String get transactionsFormCategory => 'Catégorie';

  @override
  String get transactionsFormNotePlaceholder => 'Ajouter une note...';

  @override
  String get transactionsFormIsRecurring => 'Transaction récurrente';

  @override
  String get transactionsFormRecurringAria => 'Récurrence';

  @override
  String get transactionsFeedbackRecurringFailed =>
      'Transaction créée. Échec de la récurrence.';

  @override
  String get recurringValueWeekly => 'Hebdomadaire';

  @override
  String get recurringValueMonthly => 'Mensuel';

  @override
  String get recurringValueYearly => 'Annuel';

  @override
  String recurringFeedbackValidatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions validées',
      one: '$count transaction validée',
    );
    return '$_temp0';
  }

  @override
  String get recurringFeedbackValidationError => 'Erreur lors de la validation';

  @override
  String get recurringFeedbackSkipFailed => 'Erreur lors du passage';

  @override
  String get recurringFeedbackDeactivateError =>
      'Erreur lors de la désactivation';

  @override
  String get categoriesFeedbackSystemEditForbidden =>
      'Les catégories système ne peuvent pas être modifiées';

  @override
  String get categoriesFeedbackSystemDeleteForbidden =>
      'Les catégories système ne peuvent pas être supprimées';

  @override
  String get categoriesValueSubscription => 'Abonnement';

  @override
  String get categoriesValueDebt => 'Dette';

  @override
  String get categoriesValueTransfer => 'Virement';

  @override
  String get categoriesValueAdjustment => 'Ajustement';

  @override
  String get accountsActionCreate => 'Créer un compte';

  @override
  String get accountsActionLater => 'Plus tard';

  @override
  String get accountsActionEnterRate => 'Saisir le taux';

  @override
  String accountsListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes',
      one: '$count compte',
    );
    return '$_temp0';
  }

  @override
  String get accountsDialogDeleteMessage => 'Supprimer ce compte ?';

  @override
  String get accountsFormTypeTitle => 'Type de compte';

  @override
  String get accountsFormCustomisationTitle => 'Personnalisation';

  @override
  String get accountsFormDetailsTitle => 'Détails';

  @override
  String get accountsFormBankName => 'Nom de la banque (optionnel)';

  @override
  String get accountsFormBankNamePlaceholder => 'Ex: Ma banque';

  @override
  String get accountsFormCustomLogo => 'Logo personnalisé (optionnel)';

  @override
  String get accountsFormLogoCamera => 'Caméra';

  @override
  String get accountsFormLogoGallery => 'Galerie';

  @override
  String get accountsFormRateProposalTitle => 'Taux de conversion manquant';

  @override
  String accountsFormRateProposalMessage(String from, String to) {
    return 'Aucun taux $from → $to n\'est défini.';
  }

  @override
  String get accountsFormRateProposalHint =>
      'Voulez-vous le saisir maintenant ?';

  @override
  String get exchangeRatesDialogAddRateTitle => 'Ajouter un taux';

  @override
  String recurringSummaryMonthlyExpenses(String amount) {
    return '~$amount /mois';
  }

  @override
  String get commonNavDebts => 'Dettes';

  @override
  String get commonNavSubscriptions => 'Abonnements';

  @override
  String get debtsSummaryNet => 'Solde net';

  @override
  String debtsSummaryOutstandingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours',
      one: '$count en cours',
    );
    return '$_temp0';
  }

  @override
  String debtsSummaryLentTotal(String amount) {
    return '$amount prêts';
  }

  @override
  String debtsSummaryBorrowedTotal(String amount) {
    return '$amount emprunts';
  }

  @override
  String get debtsListOverdue => 'En retard';

  @override
  String get debtsListThisWeek => 'Cette semaine';

  @override
  String get debtsListThisMonth => 'Ce mois-ci';

  @override
  String get debtsListLater => 'Plus tard';

  @override
  String get debtsListNoDueDate => 'Sans échéance';

  @override
  String get debtsListRepaid => 'Remboursées';

  @override
  String get debtsDialogCreateTitle => 'Nouvelle dette';

  @override
  String get debtsDialogEditTitle => 'Modifier la dette';

  @override
  String get debtsDialogRepayTitle => 'Remboursement';

  @override
  String get debtsValueNotRepaid => 'Non remboursé';

  @override
  String get debtsFormCurrencyPlaceholder => 'Devise par défaut';

  @override
  String debtsFormReminderSummary(String date, String time) {
    return 'Rappel : $date à $time';
  }

  @override
  String debtsDetailReminderAt(String date, String time) {
    return '$date à $time';
  }

  @override
  String get debtsActionClearReminder => 'Effacer le rappel';

  @override
  String get subscriptionsSummaryMonthlyTotal => 'Total mensuel';

  @override
  String subscriptionsSummaryActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnements',
      one: '$count abonnement',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsListActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actifs',
      one: '$count actif',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsListActive => 'Actifs';

  @override
  String get subscriptionsListInactive => 'Inactifs';

  @override
  String get subscriptionsValuePerWeek => '/sem';

  @override
  String get subscriptionsValueWeekly => 'Hebdomadaire';

  @override
  String get subscriptionsValueMonthly => 'Mensuel';

  @override
  String get subscriptionsValueYearly => 'Annuel';

  @override
  String get subscriptionsDialogCreateTitle => 'Nouvel abonnement';

  @override
  String get subscriptionsDialogEditTitle => 'Modifier l\'abonnement';

  @override
  String get subscriptionsFormCategory => 'Catégorie';

  @override
  String get subscriptionsFormCurrency => 'Devise';

  @override
  String get subscriptionsFormCurrencyPlaceholder => 'Devise par défaut';

  @override
  String get subscriptionsDetailAmount => 'Montant';

  @override
  String get subscriptionsDetailStartDate => 'Date de début';

  @override
  String get exchangeRatesValueEur => 'Euro';

  @override
  String get exchangeRatesValueXof => 'Franc CFA (BCEAO)';

  @override
  String get exchangeRatesValueUsd => 'Dollar US';

  @override
  String get exchangeRatesValueGbp => 'Livre sterling';

  @override
  String get exchangeRatesValueChf => 'Franc suisse';

  @override
  String get exchangeRatesValueCad => 'Dollar canadien';

  @override
  String get exchangeRatesValueMad => 'Dirham marocain';

  @override
  String get budgetsPageTitle => 'Budgets';

  @override
  String get budgetsPageUnbudgetedTitle => 'Non budgété';

  @override
  String get budgetsDialogCreateTitle => 'Nouveau budget';

  @override
  String get budgetsActionDeactivate => 'Désactiver';

  @override
  String get budgetsEmptyNoTransactions => 'Aucune transaction ce mois';

  @override
  String get budgetsListInactive => 'Inactifs';

  @override
  String budgetsDetailOverBudget(String amount) {
    return 'dépassement $amount';
  }

  @override
  String budgetsDetailRemaining(String amount) {
    return 'reste $amount';
  }

  @override
  String get budgetsSummarySpent => 'Dépensé';

  @override
  String budgetsSummaryActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets',
      one: '$count budget',
    );
    return '$_temp0';
  }

  @override
  String budgetsSummaryOverBudgetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en dépassement',
      one: '$count en dépassement',
    );
    return '$_temp0';
  }

  @override
  String budgetsSummaryExceededCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets dépassés',
      one: '$count budget dépassé',
    );
    return '$_temp0';
  }

  @override
  String budgetsSummaryUnbudgeted(String amount) {
    return '$amount non budgété';
  }

  @override
  String budgetsSummaryMonthlyInCurrency(String currency) {
    return 'Mensuel · en $currency';
  }

  @override
  String budgetsSummaryTotal(String amount) {
    return 'Total : $amount';
  }

  @override
  String get budgetsValueWeekly => 'Hebdomadaire';

  @override
  String get budgetsValueMonthly => 'Mensuel';

  @override
  String get budgetsValueYearly => 'Annuel';

  @override
  String get dashboardPageRecentTransactionsTitle => 'Dernières opérations';

  @override
  String dashboardSummaryGreetingMorning(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Bonjour $name',
      'other': 'Bonjour',
    });
    return '$_temp0';
  }

  @override
  String dashboardSummaryGreetingAfternoon(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Bon après-midi $name',
      'other': 'Bon après-midi',
    });
    return '$_temp0';
  }

  @override
  String dashboardSummaryGreetingEvening(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Bonsoir $name',
      'other': 'Bonsoir',
    });
    return '$_temp0';
  }

  @override
  String get dashboardSummaryMonthPositive => 'Mois positif';

  @override
  String get dashboardSummaryMonthNegative => 'Mois négatif';

  @override
  String get dashboardSummaryMonthQuiet => 'Mois calme';

  @override
  String get dashboardEmptyTitle => 'Bienvenue !';

  @override
  String get dashboardEmptyMessage =>
      'Commencez par créer un compte\npour suivre vos finances.';

  @override
  String recurringSummaryOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges en retard',
      one: '$count charge en retard',
    );
    return '$_temp0';
  }

  @override
  String get recurringActionValidate => 'Valider';

  @override
  String get recurringActionSkip => 'Passer';

  @override
  String get accountsSummaryNetWorth => 'Patrimoine total';

  @override
  String get exchangeRatesFeedbackConversionIncompleteHint =>
      'Certains montants n\'ont pas pu être convertis';

  @override
  String get transactionsEmptyTitle => 'Aucune transaction';

  @override
  String get commonActionViewAll => 'Voir tout';

  @override
  String get commonNavHome => 'Accueil';

  @override
  String get commonNavTransactions => 'Transactions';

  @override
  String get commonNavBudgets => 'Budgets';

  @override
  String get commonActionDisable => 'Désactiver';

  @override
  String get settingsPageManagementTitle => 'Gestion';

  @override
  String get settingsPageAdministrationTitle => 'Administration';

  @override
  String get settingsPageAppearanceTitle => 'Apparence';

  @override
  String get settingsPageNavigationTitle => 'Navigation';

  @override
  String get settingsPageNotificationsTitle => 'Notifications';

  @override
  String get settingsPageTimezoneTitle => 'Fuseau horaire';

  @override
  String get settingsListAccounts => 'Comptes & Devises';

  @override
  String get settingsListAccountsHint => 'Gérer les comptes et devises';

  @override
  String get settingsListCategories => 'Catégories';

  @override
  String get settingsListCategoriesHint => 'Gérer les catégories';

  @override
  String get settingsListTextScalePreview =>
      'Voici un aperçu de la taille du texte choisie.';

  @override
  String settingsListVersion(String version) {
    return 'K-Budget v$version';
  }

  @override
  String get settingsFormTheme => 'Thème';

  @override
  String get settingsFormTextScale => 'Taille du texte';

  @override
  String get settingsFormTimezoneHint => 'Pour le calcul des rappels J-1';

  @override
  String get settingsValueThemeLight => 'Clair';

  @override
  String get settingsValueThemeDark => 'Sombre';

  @override
  String get settingsValueThemeAuto => 'Auto';

  @override
  String get settingsValueTextScaleSmall => 'Petit';

  @override
  String get settingsValueTextScaleMedium => 'Normal';

  @override
  String get settingsValueTextScaleLarge => 'Grand';

  @override
  String get settingsValueChecking => 'Vérification…';

  @override
  String get settingsValueOnline => 'En ligne';

  @override
  String get settingsValueOffline => 'Hors ligne';

  @override
  String settingsDialogDisableFeatureTitle(String feature) {
    return 'Désactiver $feature ?';
  }

  @override
  String get settingsDialogDisableFeatureMessage =>
      'Vos données seront masquées mais pas supprimées.';

  @override
  String get settingsFeedbackLoadError =>
      'Impossible de charger les préférences';

  @override
  String get settingsFeedbackSaveError =>
      'Impossible de sauvegarder les préférences';

  @override
  String get settingsPageDataTitle => 'Données';

  @override
  String get settingsFormDataSource => 'Source de données';

  @override
  String get settingsValueDataSourceLocal => 'Local';

  @override
  String get settingsValueDataSourceServer => 'Serveur';

  @override
  String get settingsFormServerUrl => 'URL du serveur';

  @override
  String get settingsFormServerUrlRequired => 'L\'URL du serveur est requise';

  @override
  String get settingsFormServerUrlHttpsRequired =>
      'L\'URL doit commencer par https://';

  @override
  String get settingsFeedbackServerUrlSaved => 'URL enregistrée';

  @override
  String get settingsFeedbackServerUnreachable => 'Serveur injoignable';

  @override
  String get settingsFeedbackServerTimeout => 'Délai de connexion dépassé';

  @override
  String get settingsFeedbackServerAccessDenied =>
      'Accès refusé par le serveur';

  @override
  String get settingsFeedbackServerNotFound =>
      'Endpoint introuvable — vérifiez l\'URL';

  @override
  String get settingsDialogChangeDataSourceTitle => 'Changer de source ?';

  @override
  String get settingsDialogChangeDataSourceMessage =>
      'Les sources de données sont indépendantes. Les données de la source actuelle ne seront pas visibles après le changement.\n\nL\'application va redémarrer pour appliquer la nouvelle source.';

  @override
  String get notificationsValueSubscriptionDue => 'Échéance abonnement';

  @override
  String get notificationsValueDebtDue => 'Échéance dette';

  @override
  String get notificationsValueDebtReminder => 'Rappel dette';

  @override
  String get notificationsValueRecurringTransactionDue => 'Récurrence due';

  @override
  String get notificationsValueBudgetThreshold => 'Seuil budget atteint';

  @override
  String get notificationsValueBudgetExceeded => 'Budget dépassé';

  @override
  String get usersListProfile => 'Mon compte';

  @override
  String get usersListProfileHint => 'Profil, sécurité, déconnexion';

  @override
  String get usersListManageHint => 'Invitations et gestion des accès';

  @override
  String get usersListChangePassword => 'Changer le mot de passe';

  @override
  String get usersListExportJson => 'Exporter mes données (JSON)';

  @override
  String get usersListExportCsv => 'Exporter mes transactions (CSV)';

  @override
  String get usersPageAdminTitle => 'Utilisateurs';

  @override
  String get usersPageProfileTitle => 'Mon compte';

  @override
  String get usersPageIdentityTitle => 'Identité';

  @override
  String get usersPageSecurityTitle => 'Sécurité';

  @override
  String get usersPageDataTitle => 'Données';

  @override
  String get usersPageDangerZoneTitle => 'Zone de danger';

  @override
  String get usersFormEmailManagedHint => 'Géré par l\'admin';

  @override
  String get usersFormCurrentPassword => 'Mot de passe actuel';

  @override
  String get usersFormNewPassword => 'Nouveau mot de passe';

  @override
  String get usersFormConfirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get usersFormPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get usersFormDeleteAccountConfirm =>
      'Je comprends que cette action est définitive';

  @override
  String get usersValueNameNotSet => 'Non renseigné';

  @override
  String get usersActionDeleteAccount => 'Supprimer mon compte';

  @override
  String get usersActionChangePhoto => 'Changer la photo';

  @override
  String get usersActionDeletePhoto => 'Supprimer la photo';

  @override
  String get usersActionEditPhoto => 'Modifier la photo';

  @override
  String get usersDialogDeleteAccountMessage =>
      'Votre compte sera désactivé. Vous ne pourrez plus vous connecter avec ces identifiants. Vos données restent conservées en base pour traçabilité.';

  @override
  String get usersFeedbackProfileLoadError => 'Impossible de charger le profil';

  @override
  String get usersFeedbackNameSaveError =>
      'Impossible de sauvegarder le nom. Veuillez réessayer.';

  @override
  String get usersFeedbackExportJsonError =>
      'Erreur lors de l\'export JSON. Veuillez réessayer.';

  @override
  String get usersFeedbackExportCsvError =>
      'Erreur lors de l\'export CSV. Veuillez réessayer.';

  @override
  String get usersFeedbackDownloading => 'Téléchargement en cours…';

  @override
  String get usersFeedbackAvatarUploadError =>
      'Impossible d\'uploader la photo. Veuillez réessayer.';

  @override
  String get usersFeedbackPasswordChanged => 'Mot de passe modifié avec succès';

  @override
  String get usersFeedbackPasswordChangeError =>
      'Erreur lors du changement de mot de passe';

  @override
  String get usersFeedbackDeleteAccountError =>
      'Erreur lors de la suppression. Veuillez réessayer.';

  @override
  String get errorsApiFileTooLarge =>
      'Fichier trop volumineux. La taille maximale est 2 MB.';

  @override
  String get errorsApiInvalidImageFormat =>
      'Seuls les formats JPG et PNG sont acceptés.';

  @override
  String get commonActionEnable => 'Réactiver';

  @override
  String get authFormEmailAddress => 'Adresse email';

  @override
  String get usersPageInvitationsTab => 'Invitations';

  @override
  String get usersActionInvite => 'Inviter un utilisateur';

  @override
  String get usersActionCreateInvite => 'Créer et copier le lien';

  @override
  String get usersActionCopyLink => 'Copier le lien';

  @override
  String get usersActionRevoke => 'Révoquer';

  @override
  String get usersEmptyInvitations => 'Aucune invitation pour le moment';

  @override
  String get usersEmptyUsers => 'Aucun utilisateur trouvé';

  @override
  String get usersFormEmailPlaceholder => 'nouveau@exemple.com';

  @override
  String usersListInvitedBy(String email) {
    return 'Par $email';
  }

  @override
  String get usersValueAdmin => 'Admin';

  @override
  String get usersValueInvitationActive => 'Active';

  @override
  String get usersValueInvitationExpired => 'Expirée';

  @override
  String get usersValueInvitationUsed => 'Utilisée';

  @override
  String get usersValueInvitationRevoked => 'Révoquée';

  @override
  String get usersFeedbackLinkCopied => 'Lien copié dans le presse-papiers.';

  @override
  String get usersFeedbackInviteCreated =>
      'Invitation créée et lien copié dans le presse-papiers.';

  @override
  String get usersFeedbackInviteCreateError =>
      'Impossible de créer l\'invitation.';

  @override
  String get usersFeedbackInviteRevokeError =>
      'Impossible de révoquer l\'invitation.';

  @override
  String get usersFeedbackLoadUsersError =>
      'Impossible de charger les utilisateurs.';

  @override
  String get usersFeedbackLoadInvitationsError =>
      'Impossible de charger les invitations.';

  @override
  String get usersFeedbackUserDisableError =>
      'Impossible de désactiver l\'utilisateur.';

  @override
  String get usersFeedbackUserEnableError =>
      'Impossible de réactiver l\'utilisateur.';

  @override
  String get exchangeRatesPageTitle => 'Devises & Taux';

  @override
  String get exchangeRatesPageCurrenciesTitle => 'Mes devises';

  @override
  String get exchangeRatesPageRatesTitle => 'Taux de conversion';

  @override
  String get exchangeRatesPageCalculatorTitle => 'Calculateur';

  @override
  String get exchangeRatesDialogEditRateTitle => 'Modifier le taux';

  @override
  String get exchangeRatesDialogAddCurrencyTitle => 'Ajouter une devise';

  @override
  String exchangeRatesDialogDeleteRateMessage(
    String baseCurrency,
    String targetCurrency,
  ) {
    return 'Supprimer le taux $baseCurrency → $targetCurrency ?';
  }

  @override
  String exchangeRatesDialogRemoveTitle(String currency) {
    return 'Retirer $currency ?';
  }

  @override
  String exchangeRatesDialogRemoveMessage(String currency) {
    return 'La devise $currency est utilisée par des comptes existants. Retirer quand même ?';
  }

  @override
  String exchangeRatesDialogRemoveUnusedMessage(String currency) {
    return 'Retirer $currency de vos devises ?';
  }

  @override
  String get exchangeRatesActionRemove => 'Retirer';

  @override
  String get exchangeRatesActionRemoveCurrencyAria => 'Supprimer cette devise';

  @override
  String get exchangeRatesValuePrimary => 'Principale';

  @override
  String exchangeRatesValueCalculatedRate(String from, String rate, String to) {
    return 'Taux : 1 $from = $rate $to';
  }

  @override
  String get exchangeRatesEmptyTitle => 'Aucun taux configuré';

  @override
  String get exchangeRatesEmptyCalculator =>
      'Saisissez deux montants pour calculer le taux';

  @override
  String get exchangeRatesFeedbackLoadError =>
      'Impossible de charger les taux de change';

  @override
  String get exchangeRatesFeedbackSaveError =>
      'Erreur lors de l\'enregistrement du taux.';

  @override
  String get exchangeRatesFormBaseCurrency => 'Devise de base';

  @override
  String get exchangeRatesFormTargetCurrency => 'Devise cible';

  @override
  String get exchangeRatesFormCurrency => 'Devise';

  @override
  String get exchangeRatesFormCalculatorFrom => 'J\'ai';

  @override
  String exchangeRatesFormRateWithPair(String base, String target) {
    return 'Taux (1 $base = X $target)';
  }

  @override
  String get exchangeRatesFormRateInvalid =>
      'Veuillez saisir un taux valide (> 0).';

  @override
  String get exchangeRatesFormRatePlaceholder => 'Ex: 655.957';

  @override
  String transactionsValueTransferTo(String account) {
    return 'Virement vers $account';
  }

  @override
  String transactionsValueTransferFrom(String account) {
    return 'Virement depuis $account';
  }

  @override
  String get transactionsValueBalanceAdjustment => 'Ajustement de solde';

  @override
  String debtsValueRepayment(String person) {
    return 'Remboursement - $person';
  }

  @override
  String get accountsValueDefaultAccountName => 'Compte Principal';

  @override
  String notificationsListSubscriptionDueTitle(String name) {
    return 'Abonnement $name';
  }

  @override
  String notificationsListSubscriptionDueMessage(String name) {
    return '$name — échéance demain';
  }

  @override
  String notificationsListDebtDueTitle(String person) {
    return 'Dette $person';
  }

  @override
  String notificationsListDebtDueMessage(String person) {
    return 'Dette envers $person — échéance demain';
  }

  @override
  String notificationsListDebtReminderTitle(String person) {
    return 'Rappel dette - $person';
  }

  @override
  String notificationsListDebtReminderMessage(String amount, String person) {
    return 'Rappel : dette envers $person — $amount restant';
  }

  @override
  String notificationsListBudgetThresholdTitle(
    String category,
    String percentage,
  ) {
    return 'Budget $category : $percentage %';
  }

  @override
  String notificationsListBudgetThresholdMessage(
    String percentage,
    String category,
  ) {
    return 'Vous avez atteint $percentage % du budget $category';
  }

  @override
  String notificationsListBudgetExceededTitle(String category) {
    return 'Budget $category dépassé !';
  }

  @override
  String notificationsListBudgetExceededMessage(
    String category,
    String percentage,
  ) {
    return 'Vous avez dépassé le budget $category ($percentage %)';
  }

  @override
  String notificationsListRecurringTransactionDueTitle(String label) {
    return 'Transaction récurrente $label';
  }

  @override
  String notificationsListRecurringTransactionDueMessage(
    String label,
    String amount,
    String dueDate,
  ) {
    return '$label $amount — échéance le $dueDate';
  }

  @override
  String get notificationsPageChannelDescription => 'Notifications K-Budget';
}
