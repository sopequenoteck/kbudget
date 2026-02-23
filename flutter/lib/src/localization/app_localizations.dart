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
