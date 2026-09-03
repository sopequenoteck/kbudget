// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'K-Budget'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get navSubscriptions;

  /// No description provided for @navDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get navDebts;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Thème clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Thème sombre'**
  String get themeDark;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion réseau'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur'**
  String get errorServer;

  /// No description provided for @errorLoadingData.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données'**
  String get errorLoadingData;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get currency;

  /// No description provided for @frequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get frequency;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une catégorie'**
  String get selectCategory;

  /// No description provided for @alertThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get alertThreshold;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur K-Budget'**
  String get onboardingTitle;

  /// No description provided for @onboardingLocalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode local'**
  String get onboardingLocalTitle;

  /// No description provided for @onboardingLocalDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur cet appareil'**
  String get onboardingLocalDesc;

  /// No description provided for @onboardingServerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode serveur'**
  String get onboardingServerTitle;

  /// No description provided for @onboardingServerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisez avec votre serveur K-Budget'**
  String get onboardingServerDesc;

  /// No description provided for @onboardingChooseMode.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre mode de données'**
  String get onboardingChooseMode;

  /// No description provided for @serverUrlLabel.
  ///
  /// In fr, this message translates to:
  /// **'URL du serveur'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In fr, this message translates to:
  /// **'https://budget.example.com/api'**
  String get serverUrlHint;

  /// No description provided for @serverCheckConnection.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la connexion'**
  String get serverCheckConnection;

  /// No description provided for @serverConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get serverConnecting;

  /// No description provided for @serverConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie'**
  String get serverConnected;

  /// No description provided for @serverUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable'**
  String get serverUnreachable;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get loginInvalidCredentials;

  /// No description provided for @logoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutButton;

  /// No description provided for @lockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillage'**
  String get lockTitle;

  /// No description provided for @lockBiometric.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec la biométrie'**
  String get lockBiometric;

  /// No description provided for @lockPin.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code PIN'**
  String get lockPin;

  /// No description provided for @fabNewTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle transaction'**
  String get fabNewTransaction;

  /// No description provided for @fabNewSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel abonnement'**
  String get fabNewSubscription;

  /// No description provided for @fabNewDebt.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette'**
  String get fabNewDebt;

  /// No description provided for @transactionsEmptyMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction ce mois-ci'**
  String get transactionsEmptyMonth;

  /// No description provided for @transactionsEmptyDepenses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense ce mois-ci'**
  String get transactionsEmptyDepenses;

  /// No description provided for @transactionsEmptyRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette ce mois-ci'**
  String get transactionsEmptyRecettes;

  /// No description provided for @transactionsSummaryRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get transactionsSummaryRecettes;

  /// No description provided for @transactionsSummaryDepenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get transactionsSummaryDepenses;

  /// No description provided for @transactionsSummaryBilan.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get transactionsSummaryBilan;

  /// No description provided for @transactionsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get transactionsFilterAll;

  /// No description provided for @transactionsFilterDepenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get transactionsFilterDepenses;

  /// No description provided for @transactionsFilterRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get transactionsFilterRecettes;

  /// No description provided for @transactionsRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get transactionsRetry;

  /// No description provided for @transactionsNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get transactionsNoCategory;

  /// No description provided for @transactionFormLabelField.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get transactionFormLabelField;

  /// No description provided for @transactionFormAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get transactionFormAmountField;

  /// No description provided for @transactionFormDateField.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get transactionFormDateField;

  /// No description provided for @transactionFormNoteField.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get transactionFormNoteField;

  /// No description provided for @transactionFormAccountPicker.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get transactionFormAccountPicker;

  /// No description provided for @transactionFormCategoryPicker.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get transactionFormCategoryPicker;

  /// No description provided for @transactionFormSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get transactionFormSaveButton;

  /// No description provided for @transactionFormUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get transactionFormUpdateButton;

  /// No description provided for @transactionFormDeleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get transactionFormDeleteButton;

  /// No description provided for @transactionFormDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la transaction'**
  String get transactionFormDeleteConfirmTitle;

  /// No description provided for @transactionFormDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.'**
  String get transactionFormDeleteConfirmMessage;

  /// No description provided for @transactionFormNoAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte dans les paramètres'**
  String get transactionFormNoAccounts;

  /// No description provided for @transactionFormNoCategories.
  ///
  /// In fr, this message translates to:
  /// **'Créez une catégorie d\'abord'**
  String get transactionFormNoCategories;

  /// No description provided for @subscriptionFormNameField.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get subscriptionFormNameField;

  /// No description provided for @subscriptionFormAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get subscriptionFormAmountField;

  /// No description provided for @subscriptionFormDateField.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get subscriptionFormDateField;

  /// No description provided for @subscriptionFormAccountPicker.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get subscriptionFormAccountPicker;

  /// No description provided for @subscriptionFormCategoryPicker.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get subscriptionFormCategoryPicker;

  /// No description provided for @subscriptionFormActiveSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get subscriptionFormActiveSwitch;

  /// No description provided for @subscriptionFormSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get subscriptionFormSaveButton;

  /// No description provided for @subscriptionFormUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get subscriptionFormUpdateButton;

  /// No description provided for @subscriptionFormDeleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get subscriptionFormDeleteButton;

  /// No description provided for @subscriptionFormDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'abonnement'**
  String get subscriptionFormDeleteConfirmTitle;

  /// No description provided for @subscriptionFormDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet abonnement ? Cette action est irréversible.'**
  String get subscriptionFormDeleteConfirmMessage;

  /// No description provided for @subscriptionFormNoAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte dans les paramètres'**
  String get subscriptionFormNoAccounts;

  /// No description provided for @subscriptionFormNoCategories.
  ///
  /// In fr, this message translates to:
  /// **'Créez une catégorie d\'abord'**
  String get subscriptionFormNoCategories;

  /// No description provided for @subscriptionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement'**
  String get subscriptionsEmpty;

  /// No description provided for @subscriptionsRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get subscriptionsRetry;

  /// No description provided for @subscriptionsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get subscriptionsFilterAll;

  /// No description provided for @subscriptionsFilterActifs.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get subscriptionsFilterActifs;

  /// No description provided for @subscriptionsFilterInactifs.
  ///
  /// In fr, this message translates to:
  /// **'Inactifs'**
  String get subscriptionsFilterInactifs;

  /// No description provided for @subscriptionsTotalMensuel.
  ///
  /// In fr, this message translates to:
  /// **'Total mensuel'**
  String get subscriptionsTotalMensuel;

  /// No description provided for @subscriptionsEmptyActifs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get subscriptionsEmptyActifs;

  /// No description provided for @subscriptionsEmptyInactifs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement inactif'**
  String get subscriptionsEmptyInactifs;

  /// No description provided for @subscriptionFrequencyMensuel.
  ///
  /// In fr, this message translates to:
  /// **'/mois'**
  String get subscriptionFrequencyMensuel;

  /// No description provided for @subscriptionFrequencyAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'/an'**
  String get subscriptionFrequencyAnnuel;

  /// No description provided for @subscriptionNextRenewal.
  ///
  /// In fr, this message translates to:
  /// **'Prochain : {date}'**
  String subscriptionNextRenewal(String date);

  /// No description provided for @subscriptionBadgeInactif.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get subscriptionBadgeInactif;

  /// No description provided for @subscriptionPay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get subscriptionPay;

  /// No description provided for @subscriptionPaySuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré'**
  String get subscriptionPaySuccess;

  /// No description provided for @subscriptionPaymentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des paiements'**
  String get subscriptionPaymentHistory;

  /// No description provided for @subscriptionNoPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement'**
  String get subscriptionNoPayments;

  /// No description provided for @subscriptionPayments.
  ///
  /// In fr, this message translates to:
  /// **'{count} paiements'**
  String subscriptionPayments(int count);

  /// No description provided for @debtFormPersonField.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get debtFormPersonField;

  /// No description provided for @debtFormAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get debtFormAmountField;

  /// No description provided for @debtFormDateField.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get debtFormDateField;

  /// No description provided for @debtFormCategoryPicker.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get debtFormCategoryPicker;

  /// No description provided for @debtFormRepaidSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get debtFormRepaidSwitch;

  /// No description provided for @debtFormSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get debtFormSaveButton;

  /// No description provided for @debtFormUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get debtFormUpdateButton;

  /// No description provided for @debtFormDeleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get debtFormDeleteButton;

  /// No description provided for @debtFormDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la dette'**
  String get debtFormDeleteConfirmTitle;

  /// No description provided for @debtFormDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette dette ? Cette action est irréversible.'**
  String get debtFormDeleteConfirmMessage;

  /// No description provided for @debtFormNoCategories.
  ///
  /// In fr, this message translates to:
  /// **'Créez une catégorie d\'abord'**
  String get debtFormNoCategories;

  /// No description provided for @debtFormAccountPicker.
  ///
  /// In fr, this message translates to:
  /// **'Compte bancaire'**
  String get debtFormAccountPicker;

  /// No description provided for @debtFormAccountPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte'**
  String get debtFormAccountPlaceholder;

  /// No description provided for @debtFormDueDateField.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'échéance'**
  String get debtFormDueDateField;

  /// No description provided for @debtFormDueDatePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance'**
  String get debtFormDueDatePlaceholder;

  /// No description provided for @debtFormReminderField.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get debtFormReminderField;

  /// No description provided for @debtFormReminderPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel'**
  String get debtFormReminderPlaceholder;

  /// No description provided for @debtFormReminderTimeField.
  ///
  /// In fr, this message translates to:
  /// **'Heure de rappel'**
  String get debtFormReminderTimeField;

  /// No description provided for @debtFormIncludeInBalance.
  ///
  /// In fr, this message translates to:
  /// **'Inclure dans le patrimoine'**
  String get debtFormIncludeInBalance;

  /// No description provided for @debtsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get debtsTitle;

  /// No description provided for @debtsSummaryEmprunts.
  ///
  /// In fr, this message translates to:
  /// **'Emprunts'**
  String get debtsSummaryEmprunts;

  /// No description provided for @debtsSummaryPrets.
  ///
  /// In fr, this message translates to:
  /// **'Prêts'**
  String get debtsSummaryPrets;

  /// No description provided for @debtsSummaryNet.
  ///
  /// In fr, this message translates to:
  /// **'Solde net'**
  String get debtsSummaryNet;

  /// No description provided for @debtsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get debtsFilterAll;

  /// No description provided for @debtsFilterEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get debtsFilterEnCours;

  /// No description provided for @debtsFilterRembourse.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get debtsFilterRembourse;

  /// No description provided for @debtsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette'**
  String get debtsEmpty;

  /// No description provided for @debtsEmptyEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette en cours'**
  String get debtsEmptyEnCours;

  /// No description provided for @debtsEmptyRembourse.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette remboursée'**
  String get debtsEmptyRembourse;

  /// No description provided for @debtsSectionPrets.
  ///
  /// In fr, this message translates to:
  /// **'Prêts'**
  String get debtsSectionPrets;

  /// No description provided for @debtsSectionEmprunts.
  ///
  /// In fr, this message translates to:
  /// **'Emprunts'**
  String get debtsSectionEmprunts;

  /// No description provided for @debtBadgeRembourse.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get debtBadgeRembourse;

  /// No description provided for @debtDetailInitialAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant initial'**
  String get debtDetailInitialAmount;

  /// No description provided for @debtDetailRemainingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant restant'**
  String get debtDetailRemainingAmount;

  /// No description provided for @debtDetailRepayButton.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get debtDetailRepayButton;

  /// No description provided for @debtDetailSnoozeButton.
  ///
  /// In fr, this message translates to:
  /// **'Reporter le rappel'**
  String get debtDetailSnoozeButton;

  /// No description provided for @debtDetailProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get debtDetailProgress;

  /// No description provided for @debtDetailDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get debtDetailDate;

  /// No description provided for @debtDetailCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get debtDetailCurrency;

  /// No description provided for @debtDetailAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get debtDetailAccount;

  /// No description provided for @debtDetailAccountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get debtDetailAccountDeleted;

  /// No description provided for @debtDetailDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get debtDetailDueDate;

  /// No description provided for @debtDetailCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get debtDetailCategory;

  /// No description provided for @debtDetailIncludedInBalance.
  ///
  /// In fr, this message translates to:
  /// **'Inclus dans le solde'**
  String get debtDetailIncludedInBalance;

  /// No description provided for @debtDetailReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get debtDetailReminder;

  /// No description provided for @debtDetailPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get debtDetailPayments;

  /// No description provided for @debtDetailTotalRepaid.
  ///
  /// In fr, this message translates to:
  /// **'Total remboursé'**
  String get debtDetailTotalRepaid;

  /// No description provided for @debtDetailNoPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement enregistré'**
  String get debtDetailNoPayments;

  /// No description provided for @debtDetailPaymentsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des paiements'**
  String get debtDetailPaymentsError;

  /// No description provided for @debtDetailBadgeEmprunt.
  ///
  /// In fr, this message translates to:
  /// **'Emprunt'**
  String get debtDetailBadgeEmprunt;

  /// No description provided for @debtDetailBadgePret.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get debtDetailBadgePret;

  /// No description provided for @debtDetailBadgeRepaid.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get debtDetailBadgeRepaid;

  /// No description provided for @repayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get repayTitle;

  /// No description provided for @repayAccountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte source'**
  String get repayAccountLabel;

  /// No description provided for @repayAccountPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un compte'**
  String get repayAccountPlaceholder;

  /// No description provided for @repayAccountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Compte requis'**
  String get repayAccountRequired;

  /// No description provided for @repayAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get repayAmountLabel;

  /// No description provided for @repayAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Montant requis'**
  String get repayAmountRequired;

  /// No description provided for @repayAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get repayAmountInvalid;

  /// No description provided for @repayAmountMax.
  ///
  /// In fr, this message translates to:
  /// **'Maximum: {amount}'**
  String repayAmountMax(String amount);

  /// No description provided for @repayNoAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte actif. Créez un compte dans les paramètres.'**
  String get repayNoAccounts;

  /// No description provided for @repaySuccess.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement enregistré'**
  String get repaySuccess;

  /// No description provided for @repayError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du remboursement'**
  String get repayError;

  /// No description provided for @snoozeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reporter le rappel'**
  String get snoozeTitle;

  /// No description provided for @snoozeDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle date'**
  String get snoozeDateLabel;

  /// No description provided for @snoozeTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get snoozeTimeLabel;

  /// No description provided for @snoozeDateFutureRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date doit être dans le futur'**
  String get snoozeDateFutureRequired;

  /// No description provided for @snoozeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Rappel reporté'**
  String get snoozeSuccess;

  /// No description provided for @snoozeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du report'**
  String get snoozeError;

  /// No description provided for @snoozeSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Reporter'**
  String get snoozeSubmitButton;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @transferFormSourcePicker.
  ///
  /// In fr, this message translates to:
  /// **'Compte source'**
  String get transferFormSourcePicker;

  /// No description provided for @transferFormDestinationPicker.
  ///
  /// In fr, this message translates to:
  /// **'Compte destination'**
  String get transferFormDestinationPicker;

  /// No description provided for @transferFormAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get transferFormAmountField;

  /// No description provided for @transferFormNoteField.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get transferFormNoteField;

  /// No description provided for @transferFormSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get transferFormSaveButton;

  /// No description provided for @validationSameAccount.
  ///
  /// In fr, this message translates to:
  /// **'Les comptes source et destination doivent être différents'**
  String get validationSameAccount;

  /// No description provided for @validationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get validationRequired;

  /// No description provided for @validationAmountPositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif'**
  String get validationAmountPositive;

  /// No description provided for @validationMaxLength.
  ///
  /// In fr, this message translates to:
  /// **'Maximum {max} caractères'**
  String validationMaxLength(int max);

  /// No description provided for @accountsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get accountsTitle;

  /// No description provided for @accountsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte'**
  String get accountsEmpty;

  /// No description provided for @accountsRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get accountsRetry;

  /// No description provided for @accountsNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get accountsNewTitle;

  /// No description provided for @accountsEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte'**
  String get accountsEditTitle;

  /// No description provided for @accountTypeCourant.
  ///
  /// In fr, this message translates to:
  /// **'Courant'**
  String get accountTypeCourant;

  /// No description provided for @accountTypeEpargne.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get accountTypeEpargne;

  /// No description provided for @accountTypeEspeces.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get accountTypeEspeces;

  /// No description provided for @accountFormNameField.
  ///
  /// In fr, this message translates to:
  /// **'Nom du compte'**
  String get accountFormNameField;

  /// No description provided for @accountFormInitialBalanceField.
  ///
  /// In fr, this message translates to:
  /// **'Solde initial'**
  String get accountFormInitialBalanceField;

  /// No description provided for @accountFormCurrencyPicker.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get accountFormCurrencyPicker;

  /// No description provided for @accountFormIconField.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get accountFormIconField;

  /// No description provided for @accountFormColorField.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get accountFormColorField;

  /// No description provided for @accountFormActiveSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get accountFormActiveSwitch;

  /// No description provided for @accountFormActiveDefaultHint.
  ///
  /// In fr, this message translates to:
  /// **'Le compte par défaut ne peut pas être désactivé'**
  String get accountFormActiveDefaultHint;

  /// No description provided for @accountFormCurrentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get accountFormCurrentBalance;

  /// No description provided for @accountFormNewBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde'**
  String get accountFormNewBalance;

  /// No description provided for @accountFormPreviewPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du compte'**
  String get accountFormPreviewPlaceholder;

  /// No description provided for @accountBadgeDefault.
  ///
  /// In fr, this message translates to:
  /// **'Défaut'**
  String get accountBadgeDefault;

  /// No description provided for @accountBadgeInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get accountBadgeInactive;

  /// No description provided for @accountActionSetDefault.
  ///
  /// In fr, this message translates to:
  /// **'Définir par défaut'**
  String get accountActionSetDefault;

  /// No description provided for @accountActionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get accountActionDelete;

  /// No description provided for @accountDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get accountDeleteConfirmTitle;

  /// No description provided for @accountDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce compte ? Cette action est irréversible.'**
  String get accountDeleteConfirmMessage;

  /// No description provided for @accountErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les comptes'**
  String get accountErrorLoad;

  /// No description provided for @accountErrorCreate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création du compte'**
  String get accountErrorCreate;

  /// No description provided for @accountErrorUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la modification du compte'**
  String get accountErrorUpdate;

  /// No description provided for @accountErrorDelete.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression du compte'**
  String get accountErrorDelete;

  /// No description provided for @accountErrorSetDefault.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du changement de compte par défaut'**
  String get accountErrorSetDefault;

  /// No description provided for @accountErrorAdjustBalance.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajustement du solde'**
  String get accountErrorAdjustBalance;

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie'**
  String get categoriesEmpty;

  /// No description provided for @categoriesRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get categoriesRetry;

  /// No description provided for @categoryFormTitleCreate.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoryFormTitleCreate;

  /// No description provided for @categoryFormTitleEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get categoryFormTitleEdit;

  /// No description provided for @categoryFormNameField.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryFormNameField;

  /// No description provided for @categoryFormIconField.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get categoryFormIconField;

  /// No description provided for @categoryFormColorField.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get categoryFormColorField;

  /// No description provided for @categoryFormPreviewPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la catégorie'**
  String get categoryFormPreviewPlaceholder;

  /// No description provided for @categoryNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameMaxLength.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 30 caractères'**
  String get categoryNameMaxLength;

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom de catégorie existe déjà'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryEmojiRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'icône est requise'**
  String get categoryEmojiRequired;

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette catégorie ? Les éléments liés seront dissociés.'**
  String get categoryDeleteConfirmMessage;

  /// No description provided for @categoryErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les catégories'**
  String get categoryErrorLoad;

  /// No description provided for @categoryErrorCreate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création de la catégorie'**
  String get categoryErrorCreate;

  /// No description provided for @categoryErrorUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la modification de la catégorie'**
  String get categoryErrorUpdate;

  /// No description provided for @categoryErrorDelete.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression de la catégorie'**
  String get categoryErrorDelete;

  /// No description provided for @budgetViewCharts.
  ///
  /// In fr, this message translates to:
  /// **'Voir les graphiques'**
  String get budgetViewCharts;

  /// No description provided for @emptyBudgetList.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget'**
  String get emptyBudgetList;

  /// No description provided for @emptyBudgetCreateHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur + pour créer un budget'**
  String get emptyBudgetCreateHint;

  /// No description provided for @budgetDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails budget'**
  String get budgetDetails;

  /// No description provided for @emptyBudgetData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour ce mois'**
  String get emptyBudgetData;

  /// No description provided for @deleteBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le budget'**
  String get deleteBudgetTitle;

  /// No description provided for @deleteBudgetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce budget ? Cette action est irréversible.'**
  String get deleteBudgetMessage;

  /// No description provided for @allCategoriesHaveBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les catégories ont déjà un budget'**
  String get allCategoriesHaveBudgets;

  /// No description provided for @spent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get spent;

  /// No description provided for @budget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @budgetOtherCategory.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get budgetOtherCategory;

  /// No description provided for @budgetOtherCategoryDetail.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses non budgétées'**
  String get budgetOtherCategoryDetail;

  /// No description provided for @budgetActive.
  ///
  /// In fr, this message translates to:
  /// **'Budget actif'**
  String get budgetActive;

  /// No description provided for @budgetShowInactive.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les inactifs'**
  String get budgetShowInactive;

  /// No description provided for @notificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer lu'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationClearHistory.
  ///
  /// In fr, this message translates to:
  /// **'Vider l\'historique'**
  String get notificationClearHistory;

  /// No description provided for @notificationEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationEmpty;

  /// No description provided for @notificationClearConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider l\'historique'**
  String get notificationClearConfirmTitle;

  /// No description provided for @notificationClearConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer toutes les notifications ? Cette action est irréversible.'**
  String get notificationClearConfirmMessage;

  /// No description provided for @notificationRepayTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get notificationRepayTooltip;

  /// No description provided for @notificationSnoozeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Reporter'**
  String get notificationSnoozeTooltip;

  /// No description provided for @notificationLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la dette'**
  String get notificationLoadError;

  /// No description provided for @notificationGroupToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get notificationGroupToday;

  /// No description provided for @notificationGroupYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationGroupYesterday;

  /// No description provided for @recurringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récurrences'**
  String get recurringTitle;

  /// No description provided for @recurringOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get recurringOverdue;

  /// No description provided for @recurringToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get recurringToday;

  /// No description provided for @recurringUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get recurringUpcoming;

  /// No description provided for @recurringValidate.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payée'**
  String get recurringValidate;

  /// No description provided for @recurringSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette occurrence'**
  String get recurringSkip;

  /// No description provided for @recurringDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la récurrence'**
  String get recurringDeactivate;

  /// No description provided for @recurringValidateAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout payé'**
  String get recurringValidateAll;

  /// No description provided for @recurringNextOccurrence.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine : {date}'**
  String recurringNextOccurrence(String date);

  /// No description provided for @recurringMonthlySummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'BILAN MENSUEL'**
  String get recurringMonthlySummaryTitle;

  /// No description provided for @recurringChargesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} CHARGES'**
  String recurringChargesCount(int count);

  /// No description provided for @recurringEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récurrence active'**
  String get recurringEmpty;

  /// No description provided for @recurringDeactivateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver cette récurrence ?'**
  String get recurringDeactivateConfirm;

  /// No description provided for @recurringValidateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Transaction créée'**
  String get recurringValidateSuccess;

  /// No description provided for @recurringSkipSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Échéance avancée'**
  String get recurringSkipSuccess;

  /// No description provided for @recurringDeactivateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence désactivée'**
  String get recurringDeactivateSuccess;

  /// No description provided for @frequencyHebdomadaire.
  ///
  /// In fr, this message translates to:
  /// **'/semaine'**
  String get frequencyHebdomadaire;

  /// No description provided for @frequencyMensuel.
  ///
  /// In fr, this message translates to:
  /// **'/mois'**
  String get frequencyMensuel;

  /// No description provided for @frequencyAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'/an'**
  String get frequencyAnnuel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
