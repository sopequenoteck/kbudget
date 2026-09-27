// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @commonActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonActionCancel;

  /// No description provided for @commonActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonActionSave;

  /// No description provided for @commonActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonActionDelete;

  /// No description provided for @commonActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonActionEdit;

  /// No description provided for @commonActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonActionRetry;

  /// No description provided for @errorsClientGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorsClientGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network connection error'**
  String get errorNetwork;

  /// No description provided for @errorsApiBadRequest.
  ///
  /// In en, this message translates to:
  /// **'The request could not be processed.'**
  String get errorsApiBadRequest;

  /// No description provided for @errorsApiValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please check the information you entered.'**
  String get errorsApiValidationError;

  /// No description provided for @errorsApiMalformedRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request.'**
  String get errorsApiMalformedRequest;

  /// No description provided for @errorCodePasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get errorCodePasswordIncorrect;

  /// No description provided for @errorCodeCurrentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password incorrect'**
  String get errorCodeCurrentPasswordIncorrect;

  /// No description provided for @errorCodePasswordUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one'**
  String get errorCodePasswordUnchanged;

  /// No description provided for @errorsApiConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Explicit confirmation required.'**
  String get errorsApiConfirmationRequired;

  /// No description provided for @errorCodeUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get errorCodeUnauthenticated;

  /// No description provided for @errorsApiTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorsApiTokenExpired;

  /// No description provided for @errorsApiTokenRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your session has been revoked. Please sign in again.'**
  String get errorsApiTokenRevoked;

  /// No description provided for @errorsApiTokenReuseDetected.
  ///
  /// In en, this message translates to:
  /// **'Session interrupted for security reasons. Please sign in again.'**
  String get errorsApiTokenReuseDetected;

  /// No description provided for @errorsApiTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid session. Please sign in again.'**
  String get errorsApiTokenInvalid;

  /// No description provided for @errorsApiAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorsApiAccessDenied;

  /// No description provided for @errorCodePasswordResetRequired.
  ///
  /// In en, this message translates to:
  /// **'Credentials reset required'**
  String get errorCodePasswordResetRequired;

  /// No description provided for @errorsApiPasswordResetNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Credentials reset is not required for this account.'**
  String get errorsApiPasswordResetNotRequired;

  /// No description provided for @errorsApiFeatureDisabled.
  ///
  /// In en, this message translates to:
  /// **'Feature disabled'**
  String get errorsApiFeatureDisabled;

  /// No description provided for @errorCodeLastAdminDeletionForbidden.
  ///
  /// In en, this message translates to:
  /// **'You are the last administrator. Please appoint another administrator before deleting your account.'**
  String get errorCodeLastAdminDeletionForbidden;

  /// No description provided for @errorsApiNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get errorsApiNotFound;

  /// No description provided for @errorsApiConflict.
  ///
  /// In en, this message translates to:
  /// **'Data conflict'**
  String get errorsApiConflict;

  /// No description provided for @errorsApiLastAdminCannotBeDisabled.
  ///
  /// In en, this message translates to:
  /// **'The last active administrator cannot be disabled.'**
  String get errorsApiLastAdminCannotBeDisabled;

  /// No description provided for @errorsApiEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get errorsApiEmailAlreadyExists;

  /// No description provided for @errorsApiTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again shortly.'**
  String get errorsApiTooManyRequests;

  /// No description provided for @errorsApiInternalError.
  ///
  /// In en, this message translates to:
  /// **'An internal error occurred'**
  String get errorsApiInternalError;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @budgetsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetsFormCategory;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get selectCategory;

  /// No description provided for @budgetsFormThresholdAria.
  ///
  /// In en, this message translates to:
  /// **'Alert threshold'**
  String get budgetsFormThresholdAria;

  /// No description provided for @authFeedbackInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get authFeedbackInvalidCredentials;

  /// No description provided for @transactionsEmptyMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get transactionsEmptyMonth;

  /// No description provided for @transactionsNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get transactionsNoCategory;

  /// No description provided for @transactionsFormDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transactionsFormDescriptionPlaceholder;

  /// No description provided for @transactionsFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionsFormAccount;

  /// No description provided for @transactionFormDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get transactionFormDeleteConfirmTitle;

  /// No description provided for @transactionFormDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction? This action is irreversible.'**
  String get transactionFormDeleteConfirmMessage;

  /// No description provided for @subscriptionsFormNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subscriptionsFormNamePlaceholder;

  /// No description provided for @subscriptionsFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get subscriptionsFormAccount;

  /// No description provided for @commonValueActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonValueActive;

  /// No description provided for @subscriptionFormDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription'**
  String get subscriptionFormDeleteConfirmTitle;

  /// No description provided for @subscriptionFormDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this subscription? This action is irreversible.'**
  String get subscriptionFormDeleteConfirmMessage;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsValuePerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get subscriptionsValuePerMonth;

  /// No description provided for @subscriptionsValuePerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get subscriptionsValuePerYear;

  /// No description provided for @subscriptionNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String subscriptionNextRenewal(String date);

  /// No description provided for @commonValueInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get commonValueInactive;

  /// No description provided for @subscriptionsActionPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get subscriptionsActionPay;

  /// No description provided for @subscriptionsFeedbackPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get subscriptionsFeedbackPaid;

  /// No description provided for @subscriptionPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get subscriptionPaymentHistory;

  /// No description provided for @subscriptionNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments'**
  String get subscriptionNoPayments;

  /// No description provided for @subscriptionPayments.
  ///
  /// In en, this message translates to:
  /// **'{count} payments'**
  String subscriptionPayments(int count);

  /// No description provided for @debtsFormPersonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get debtsFormPersonPlaceholder;

  /// No description provided for @debtFormDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete debt'**
  String get debtFormDeleteConfirmTitle;

  /// No description provided for @debtFormDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this debt? This action is irreversible.'**
  String get debtFormDeleteConfirmMessage;

  /// No description provided for @debtFormAccountPicker.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get debtFormAccountPicker;

  /// No description provided for @debtsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No debts'**
  String get debtsEmptyTitle;

  /// No description provided for @debtsValueRepaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid'**
  String get debtsValueRepaid;

  /// No description provided for @debtDetailInitialAmount.
  ///
  /// In en, this message translates to:
  /// **'Initial amount'**
  String get debtDetailInitialAmount;

  /// No description provided for @debtDetailRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get debtDetailRemainingAmount;

  /// No description provided for @debtsActionRepay.
  ///
  /// In en, this message translates to:
  /// **'Repay'**
  String get debtsActionRepay;

  /// No description provided for @debtsDialogSnoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze the reminder'**
  String get debtsDialogSnoozeTitle;

  /// No description provided for @debtDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get debtDetailProgress;

  /// No description provided for @debtDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get debtDetailDate;

  /// No description provided for @debtDetailCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get debtDetailCurrency;

  /// No description provided for @debtsFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get debtsFormAccount;

  /// No description provided for @debtDetailAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get debtDetailAccountDeleted;

  /// No description provided for @debtDetailDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get debtDetailDueDate;

  /// No description provided for @debtsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get debtsFormCategory;

  /// No description provided for @debtDetailIncludedInBalance.
  ///
  /// In en, this message translates to:
  /// **'Included in balance'**
  String get debtDetailIncludedInBalance;

  /// No description provided for @debtsFormReminderAria.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get debtsFormReminderAria;

  /// No description provided for @debtsDetailPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get debtsDetailPayments;

  /// No description provided for @debtDetailTotalRepaid.
  ///
  /// In en, this message translates to:
  /// **'Total repaid'**
  String get debtDetailTotalRepaid;

  /// No description provided for @commonEmptyNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded'**
  String get commonEmptyNoPayments;

  /// No description provided for @debtDetailPaymentsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load payments'**
  String get debtDetailPaymentsError;

  /// No description provided for @debtsValueBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get debtsValueBorrowed;

  /// No description provided for @debtsValueLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get debtsValueLent;

  /// No description provided for @repayAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get repayAccountLabel;

  /// No description provided for @debtsFormAccountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get debtsFormAccountPlaceholder;

  /// No description provided for @repayAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Account required'**
  String get repayAccountRequired;

  /// No description provided for @repayAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get repayAmountLabel;

  /// No description provided for @repayAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required'**
  String get repayAmountRequired;

  /// No description provided for @debtsFeedbackAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get debtsFeedbackAmountInvalid;

  /// No description provided for @repayAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum: {amount}'**
  String repayAmountMax(String amount);

  /// No description provided for @repayNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No active accounts. Create an account in settings.'**
  String get repayNoAccounts;

  /// No description provided for @repaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Repayment recorded'**
  String get repaySuccess;

  /// No description provided for @debtsFeedbackRepayError.
  ///
  /// In en, this message translates to:
  /// **'Repayment failed'**
  String get debtsFeedbackRepayError;

  /// No description provided for @snoozeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get snoozeDateLabel;

  /// No description provided for @snoozeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get snoozeTimeLabel;

  /// No description provided for @snoozeDateFutureRequired.
  ///
  /// In en, this message translates to:
  /// **'The date must be in the future'**
  String get snoozeDateFutureRequired;

  /// No description provided for @debtsFeedbackSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed'**
  String get debtsFeedbackSnoozed;

  /// No description provided for @snoozeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to snooze the reminder'**
  String get snoozeError;

  /// No description provided for @debtsActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get debtsActionSnooze;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @transactionsFormTransferFromPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get transactionsFormTransferFromPlaceholder;

  /// No description provided for @transactionsFormTransferToPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get transactionsFormTransferToPlaceholder;

  /// No description provided for @transactionsFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionsFormAmount;

  /// No description provided for @transactionsFormNoteAria.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionsFormNoteAria;

  /// No description provided for @transferFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get transferFormSaveButton;

  /// No description provided for @transactionsFormTransferAccountsMismatch.
  ///
  /// In en, this message translates to:
  /// **'The source and destination accounts must be different'**
  String get transactionsFormTransferAccountsMismatch;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'The amount must be positive'**
  String get validationAmountPositive;

  /// No description provided for @validationMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} characters'**
  String validationMaxLength(int max);

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get accountsEmptyTitle;

  /// No description provided for @accountsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountsDialogCreateTitle;

  /// No description provided for @accountsDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountsDialogEditTitle;

  /// No description provided for @accountsValueCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get accountsValueCurrent;

  /// No description provided for @accountsValueSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountsValueSavings;

  /// No description provided for @accountsValueCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountsValueCash;

  /// No description provided for @accountsFormName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountsFormName;

  /// No description provided for @accountsFormOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountsFormOpeningBalance;

  /// No description provided for @accountsFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountsFormCurrency;

  /// No description provided for @accountsFormIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get accountsFormIcon;

  /// No description provided for @commonFormColour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get commonFormColour;

  /// No description provided for @accountFormActiveDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'The default account cannot be deactivated'**
  String get accountFormActiveDefaultHint;

  /// No description provided for @accountsFormCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get accountsFormCurrentBalance;

  /// No description provided for @accountsFormNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get accountsFormNewBalance;

  /// No description provided for @accountFormPreviewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Account preview'**
  String get accountFormPreviewPlaceholder;

  /// No description provided for @accountsValueDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accountsValueDefault;

  /// No description provided for @accountDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteConfirmTitle;

  /// No description provided for @accountDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account? This action is irreversible.'**
  String get accountDeleteConfirmMessage;

  /// No description provided for @accountErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load accounts'**
  String get accountErrorLoad;

  /// No description provided for @accountErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Error creating account'**
  String get accountErrorCreate;

  /// No description provided for @accountErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating account'**
  String get accountErrorUpdate;

  /// No description provided for @accountErrorDelete.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account'**
  String get accountErrorDelete;

  /// No description provided for @categoriesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesPageTitle;

  /// No description provided for @categoriesEmptyNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get categoriesEmptyNoCategories;

  /// No description provided for @categoriesDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoriesDialogCreateTitle;

  /// No description provided for @categoriesDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoriesDialogEditTitle;

  /// No description provided for @categoryFormNameField.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryFormNameField;

  /// No description provided for @categoryFormIconField.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryFormIconField;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'30 characters maximum'**
  String get categoryNameMaxLength;

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This category name already exists'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryEmojiRequired.
  ///
  /// In en, this message translates to:
  /// **'Icon is required'**
  String get categoryEmojiRequired;

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category? Related items will be unlinked.'**
  String get categoryDeleteConfirmMessage;

  /// No description provided for @categoryErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load categories'**
  String get categoryErrorLoad;

  /// No description provided for @categoryErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Error creating category'**
  String get categoryErrorCreate;

  /// No description provided for @categoryErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get categoryErrorUpdate;

  /// No description provided for @categoryErrorDelete.
  ///
  /// In en, this message translates to:
  /// **'Error deleting category'**
  String get categoryErrorDelete;

  /// No description provided for @emptyBudgetList.
  ///
  /// In en, this message translates to:
  /// **'No budget'**
  String get emptyBudgetList;

  /// No description provided for @deleteBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get deleteBudgetTitle;

  /// No description provided for @deleteBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget? This action is irreversible.'**
  String get deleteBudgetMessage;

  /// No description provided for @allCategoriesHaveBudgets.
  ///
  /// In en, this message translates to:
  /// **'All categories already have a budget'**
  String get allCategoriesHaveBudgets;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @budgetOtherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get budgetOtherCategory;

  /// No description provided for @budgetActive.
  ///
  /// In en, this message translates to:
  /// **'Active budget'**
  String get budgetActive;

  /// No description provided for @notificationsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPageTitle;

  /// No description provided for @notificationsActionMarkAllReadHint.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsActionMarkAllReadHint;

  /// No description provided for @notificationsActionDeleteAllHint.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get notificationsActionDeleteAllHint;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications? This action is irreversible.'**
  String get notificationClearConfirmMessage;

  /// No description provided for @debtsFeedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load debt'**
  String get debtsFeedbackLoadError;

  /// No description provided for @commonValueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonValueToday;

  /// No description provided for @commonValueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonValueYesterday;

  /// No description provided for @recurringPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringPageTitle;

  /// No description provided for @recurringValueOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get recurringValueOverdue;

  /// No description provided for @recurringValueUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get recurringValueUpcoming;

  /// No description provided for @recurringActionMarkAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get recurringActionMarkAsPaid;

  /// No description provided for @recurringActionSkipOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Skip this occurrence'**
  String get recurringActionSkipOccurrence;

  /// No description provided for @recurringActionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate the recurring transaction'**
  String get recurringActionDeactivate;

  /// No description provided for @recurringActionPayAll.
  ///
  /// In en, this message translates to:
  /// **'All paid'**
  String get recurringActionPayAll;

  /// No description provided for @recurringNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringNextOccurrence(String date);

  /// No description provided for @recurringMonthlySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY SUMMARY'**
  String get recurringMonthlySummaryTitle;

  /// No description provided for @recurringChargesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} EXPENSES'**
  String recurringChargesCount(int count);

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active recurring transactions'**
  String get recurringEmpty;

  /// No description provided for @recurringFeedbackValidated.
  ///
  /// In en, this message translates to:
  /// **'Transaction created'**
  String get recurringFeedbackValidated;

  /// No description provided for @recurringSkipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Occurrence skipped'**
  String get recurringSkipSuccess;

  /// No description provided for @recurringFeedbackDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deactivated'**
  String get recurringFeedbackDeactivated;

  /// No description provided for @frequencyHebdomadaire.
  ///
  /// In en, this message translates to:
  /// **'/week'**
  String get frequencyHebdomadaire;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
