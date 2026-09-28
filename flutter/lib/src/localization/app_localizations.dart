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

  /// No description provided for @errorsClientNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server'**
  String get errorsClientNetwork;

  /// No description provided for @errorsClientUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorsClientUnknown;

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

  /// No description provided for @errorsApiPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get errorsApiPasswordIncorrect;

  /// No description provided for @usersFeedbackCurrentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password incorrect.'**
  String get usersFeedbackCurrentPasswordIncorrect;

  /// No description provided for @usersFeedbackLastAdminDeletionForbidden.
  ///
  /// In en, this message translates to:
  /// **'You are the last administrator. Please appoint another administrator before deleting your account.'**
  String get usersFeedbackLastAdminDeletionForbidden;

  /// No description provided for @errorsApiPasswordUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get errorsApiPasswordUnchanged;

  /// No description provided for @errorsApiConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Explicit confirmation required.'**
  String get errorsApiConfirmationRequired;

  /// No description provided for @errorsApiUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Authentication required.'**
  String get errorsApiUnauthenticated;

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

  /// No description provided for @errorsApiPasswordResetRequired.
  ///
  /// In en, this message translates to:
  /// **'Credentials reset required'**
  String get errorsApiPasswordResetRequired;

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

  /// No description provided for @errorsApiLastAdminDeletionForbidden.
  ///
  /// In en, this message translates to:
  /// **'At least one active administrator must exist.'**
  String get errorsApiLastAdminDeletionForbidden;

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

  /// No description provided for @transactionsEmptyNoneInMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions in {month}'**
  String transactionsEmptyNoneInMonth(String month);

  /// No description provided for @transactionsListNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get transactionsListNoCategory;

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

  /// No description provided for @transactionsDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get transactionsDialogDeleteTitle;

  /// No description provided for @transactionsDialogDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get transactionsDialogDeleteMessage;

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

  /// No description provided for @transactionsActionTransferSubmit.
  ///
  /// In en, this message translates to:
  /// **'Make the transfer'**
  String get transactionsActionTransferSubmit;

  /// No description provided for @transactionsFormTransferAccountsMismatch.
  ///
  /// In en, this message translates to:
  /// **'The source and destination accounts must be different'**
  String get transactionsFormTransferAccountsMismatch;

  /// No description provided for @commonValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get commonValidationRequired;

  /// No description provided for @commonValidationAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'The amount must be greater than 0'**
  String get commonValidationAmountPositive;

  /// No description provided for @commonValidationMaxLength.
  ///
  /// In en, this message translates to:
  /// **'{max} characters maximum'**
  String commonValidationMaxLength(int max);

  /// No description provided for @accountsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsPageTitle;

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

  /// No description provided for @accountsFormActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Set another default account before deactivating this one'**
  String get accountsFormActiveHint;

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

  /// No description provided for @accountsFormPreviewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Account preview'**
  String get accountsFormPreviewPlaceholder;

  /// No description provided for @accountsValueDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accountsValueDefault;

  /// No description provided for @accountsDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountsDialogDeleteTitle;

  /// No description provided for @accountsDialogDeleteWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account? This action is irreversible.'**
  String get accountsDialogDeleteWarningMessage;

  /// No description provided for @accountsFeedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get accountsFeedbackLoadError;

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

  /// No description provided for @categoriesFormName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoriesFormName;

  /// No description provided for @categoriesFormIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoriesFormIcon;

  /// No description provided for @commonValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get commonValidationNameRequired;

  /// No description provided for @categoriesFormNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'30 characters maximum'**
  String get categoriesFormNameMaxLength;

  /// No description provided for @categoriesFormNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This category name already exists'**
  String get categoriesFormNameDuplicate;

  /// No description provided for @categoriesFormIconRequired.
  ///
  /// In en, this message translates to:
  /// **'Icon is required'**
  String get categoriesFormIconRequired;

  /// No description provided for @categoriesDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoriesDialogDeleteTitle;

  /// No description provided for @categoriesDialogDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This category will be unlinked from all related items.'**
  String get categoriesDialogDeleteMessage;

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

  /// No description provided for @recurringDetailNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringDetailNext(String date);

  /// No description provided for @recurringSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly summary'**
  String get recurringSummaryTitle;

  /// No description provided for @recurringSummaryExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} expense} other {{count} expenses}}'**
  String recurringSummaryExpenseCount(int count);

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringFeedbackValidatedOne.
  ///
  /// In en, this message translates to:
  /// **'Transaction validated'**
  String get recurringFeedbackValidatedOne;

  /// No description provided for @recurringFeedbackSkipped.
  ///
  /// In en, this message translates to:
  /// **'Occurrence skipped'**
  String get recurringFeedbackSkipped;

  /// No description provided for @recurringFeedbackDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction deactivated'**
  String get recurringFeedbackDeactivated;

  /// No description provided for @authPageLoginTagline.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authPageLoginTagline;

  /// No description provided for @authFormEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get authFormEmailRequired;

  /// No description provided for @authFormPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get authFormPasswordRequired;

  /// No description provided for @authPageFirstLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'First sign-in'**
  String get authPageFirstLoginTitle;

  /// No description provided for @authPageFirstLoginNotice.
  ///
  /// In en, this message translates to:
  /// **'You are signed in with the initial credentials generated by the system. Set your final email, a personal password and your display name now to access the application.'**
  String get authPageFirstLoginNotice;

  /// No description provided for @authFormDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required (100 characters max)'**
  String get authFormDisplayNameRequired;

  /// No description provided for @authFeedbackResetError.
  ///
  /// In en, this message translates to:
  /// **'Error updating your credentials. Please try again.'**
  String get authFeedbackResetError;

  /// No description provided for @authFormPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authFormPasswordConfirmRequired;

  /// No description provided for @authFeedbackInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid, expired, already used or revoked link.'**
  String get authFeedbackInvalidLink;

  /// No description provided for @authFeedbackCreateAccountError.
  ///
  /// In en, this message translates to:
  /// **'Error creating the account. Please try again.'**
  String get authFeedbackCreateAccountError;

  /// No description provided for @authFeedbackCheckingLink.
  ///
  /// In en, this message translates to:
  /// **'Checking the link...'**
  String get authFeedbackCheckingLink;

  /// No description provided for @authPageInvalidLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get authPageInvalidLinkTitle;

  /// No description provided for @authActionBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign-in'**
  String get authActionBackToLogin;

  /// No description provided for @authPageAcceptInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authPageAcceptInviteTitle;

  /// No description provided for @authPageAcceptInviteTagline.
  ///
  /// In en, this message translates to:
  /// **'A few details to finish signing up'**
  String get authPageAcceptInviteTagline;

  /// No description provided for @authFormEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFormEmail;

  /// No description provided for @authFormEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authFormEmailInvalid;

  /// No description provided for @authFormPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFormPassword;

  /// No description provided for @authFormDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authFormDisplayName;

  /// No description provided for @authFormConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFormConfirmPassword;

  /// No description provided for @authFormPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authFormPasswordMismatch;

  /// No description provided for @authFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get authFormCurrency;

  /// No description provided for @authActionCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get authActionCreateAccount;

  /// No description provided for @authActionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authActionSignIn;

  /// No description provided for @authFormPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'{min} characters minimum'**
  String authFormPasswordMinLength(int min);

  /// No description provided for @authActionUnlockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock K-Budget'**
  String get authActionUnlockBiometricReason;

  /// No description provided for @authFeedbackBiometricError.
  ///
  /// In en, this message translates to:
  /// **'Biometric error. Use your PIN.'**
  String get authFeedbackBiometricError;

  /// No description provided for @authFormPinMinLength.
  ///
  /// In en, this message translates to:
  /// **'The PIN must contain at least 4 digits'**
  String get authFormPinMinLength;

  /// No description provided for @authFeedbackPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get authFeedbackPinIncorrect;

  /// No description provided for @authDialogForgotPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN?'**
  String get authDialogForgotPinTitle;

  /// No description provided for @authDialogForgotPinServerMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out and will need to sign in again with your credentials.'**
  String get authDialogForgotPinServerMessage;

  /// No description provided for @authDialogForgotPinLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'In local mode, resetting the PIN will erase all your data. This action is irreversible.'**
  String get authDialogForgotPinLocalMessage;

  /// No description provided for @authPagePinTagline.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get authPagePinTagline;

  /// No description provided for @authActionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get authActionUnlock;

  /// No description provided for @authActionBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get authActionBiometric;

  /// No description provided for @commonActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonActionConfirm;

  /// No description provided for @commonActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonActionClose;

  /// No description provided for @commonActionChooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose an emoji'**
  String get commonActionChooseEmoji;

  /// No description provided for @commonFormEmojiSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for an emoji…'**
  String get commonFormEmojiSearchPlaceholder;

  /// No description provided for @commonEmptyNoRecentEmoji.
  ///
  /// In en, this message translates to:
  /// **'No recent emoji'**
  String get commonEmptyNoRecentEmoji;

  /// No description provided for @transactionsActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionsActionCreate;

  /// No description provided for @subscriptionsActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionsActionCreate;

  /// No description provided for @debtsActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtsActionCreate;

  /// No description provided for @budgetsActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetsActionCreate;

  /// No description provided for @transactionsActionTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionsActionTransfer;

  /// No description provided for @commonActionPreviousMonthAria.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get commonActionPreviousMonthAria;

  /// No description provided for @commonActionNextMonthAria.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get commonActionNextMonthAria;

  /// No description provided for @commonNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonNavSettings;

  /// No description provided for @commonActionLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonActionLogout;

  /// No description provided for @commonActionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonActionReset;

  /// No description provided for @commonFormSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get commonFormSearchPlaceholder;

  /// No description provided for @commonFormSelectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get commonFormSelectPlaceholder;

  /// No description provided for @commonEmptyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get commonEmptyNoResults;

  /// No description provided for @categoriesActionCreateNamed.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String categoriesActionCreateNamed(String name);

  /// No description provided for @categoriesFormSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for a category…'**
  String get categoriesFormSearchPlaceholder;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet — create one'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get categoriesActionCreate;

  /// No description provided for @categoriesListNoResults.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoriesListNoResults;

  /// No description provided for @commonActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonActionBack;

  /// No description provided for @accountsFormSelectBankPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select a bank'**
  String get accountsFormSelectBankPlaceholder;

  /// No description provided for @accountsFormBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountsFormBankTitle;

  /// No description provided for @accountsValueOtherCustom.
  ///
  /// In en, this message translates to:
  /// **'Other / Custom'**
  String get accountsValueOtherCustom;

  /// No description provided for @accountsFilterBankSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for a bank…'**
  String get accountsFilterBankSearchPlaceholder;

  /// No description provided for @accountsFeedbackBanksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load banks'**
  String get accountsFeedbackBanksLoadError;

  /// No description provided for @accountsEmptyBankNotFound.
  ///
  /// In en, this message translates to:
  /// **'No bank found'**
  String get accountsEmptyBankNotFound;

  /// No description provided for @accountsListBankGroupFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get accountsListBankGroupFrance;

  /// No description provided for @accountsListBankGroupWestAfrica.
  ///
  /// In en, this message translates to:
  /// **'West Africa'**
  String get accountsListBankGroupWestAfrica;

  /// No description provided for @accountsListBankGroupInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get accountsListBankGroupInternational;

  /// No description provided for @commonFeedbackSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get commonFeedbackSaveError;

  /// No description provided for @commonFeedbackDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get commonFeedbackDeleteError;

  /// No description provided for @commonFeedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get commonFeedbackLoadError;

  /// No description provided for @onboardingDialogSwitchToLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to local mode?'**
  String get onboardingDialogSwitchToLocalTitle;

  /// No description provided for @onboardingDialogSwitchToLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data will be stored only on this device. You can switch back to server mode from settings.'**
  String get onboardingDialogSwitchToLocalMessage;

  /// No description provided for @onboardingActionUseLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Use in local mode'**
  String get onboardingActionUseLocalMode;

  /// No description provided for @onboardingPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to K-Budget'**
  String get onboardingPageTitle;

  /// No description provided for @onboardingPageTagline.
  ///
  /// In en, this message translates to:
  /// **'Choose your data mode'**
  String get onboardingPageTagline;

  /// No description provided for @onboardingValueLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Local mode'**
  String get onboardingValueLocalMode;

  /// No description provided for @onboardingValueLocalModeHint.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get onboardingValueLocalModeHint;

  /// No description provided for @onboardingValueServerMode.
  ///
  /// In en, this message translates to:
  /// **'Server mode'**
  String get onboardingValueServerMode;

  /// No description provided for @onboardingValueServerModeHint.
  ///
  /// In en, this message translates to:
  /// **'Sync with your K-Budget server'**
  String get onboardingValueServerModeHint;

  /// No description provided for @onboardingPageServerSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Server setup'**
  String get onboardingPageServerSetupTitle;

  /// No description provided for @onboardingFormServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your K-Budget server URL'**
  String get onboardingFormServerUrlHint;

  /// No description provided for @onboardingFormServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get onboardingFormServerUrl;

  /// No description provided for @onboardingFormServerUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'The URL is required'**
  String get onboardingFormServerUrlRequired;

  /// No description provided for @onboardingFormServerUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get onboardingFormServerUrlInvalid;

  /// No description provided for @onboardingFeedbackConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get onboardingFeedbackConnected;

  /// No description provided for @onboardingFeedbackConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get onboardingFeedbackConnecting;

  /// No description provided for @onboardingActionCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get onboardingActionCheckConnection;

  /// No description provided for @compatibilityPageClientTitle.
  ///
  /// In en, this message translates to:
  /// **'App update required'**
  String get compatibilityPageClientTitle;

  /// No description provided for @compatibilityPageServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server update required'**
  String get compatibilityPageServerTitle;

  /// No description provided for @compatibilityPageTagline.
  ///
  /// In en, this message translates to:
  /// **'This version of the application and your server cannot work together.'**
  String get compatibilityPageTagline;

  /// No description provided for @compatibilityFeedbackOffline.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Check the URL and your connection.'**
  String get compatibilityFeedbackOffline;

  /// No description provided for @compatibilityFeedbackServerTooOldUnknown.
  ///
  /// In en, this message translates to:
  /// **'This server is too old to report its version. This application requires at least version {requiredVersion}. Update your instance, then restart the application.'**
  String compatibilityFeedbackServerTooOldUnknown(String requiredVersion);

  /// No description provided for @compatibilityFeedbackServerTooOldVersion.
  ///
  /// In en, this message translates to:
  /// **'This server is running version {serverVersion}. This application requires at least version {requiredVersion}. Update your instance, then restart the application.'**
  String compatibilityFeedbackServerTooOldVersion(
    String serverVersion,
    String requiredVersion,
  );

  /// No description provided for @compatibilityFeedbackClientTooOld.
  ///
  /// In en, this message translates to:
  /// **'This server requires at least version {requiredVersion} of the application. Update K-Budget from your app store.'**
  String compatibilityFeedbackClientTooOld(String requiredVersion);

  /// No description provided for @compatibilityFeedbackClientTooOldVerbose.
  ///
  /// In en, this message translates to:
  /// **'This server requires at least version {requiredVersion} of the application. You are using version {clientVersion}. Update K-Budget from your app store.'**
  String compatibilityFeedbackClientTooOldVerbose(
    String requiredVersion,
    String clientVersion,
  );

  /// No description provided for @commonValueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonValueTomorrow;

  /// No description provided for @commonValueDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} day ago} other {{count} days ago}}'**
  String commonValueDaysAgo(int count);

  /// No description provided for @commonValueWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} week ago} other {{count} weeks ago}}'**
  String commonValueWeeksAgo(int count);

  /// No description provided for @commonValueDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String commonValueDaysAgoShort(int count);

  /// No description provided for @commonValueInDaysShort.
  ///
  /// In en, this message translates to:
  /// **'in {count}d'**
  String commonValueInDaysShort(int count);

  /// No description provided for @dashboardSummaryMonthVariation.
  ///
  /// In en, this message translates to:
  /// **'{amount} this month'**
  String dashboardSummaryMonthVariation(String amount);

  /// No description provided for @transactionsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsPageTitle;

  /// No description provided for @transactionsListThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get transactionsListThisWeek;

  /// No description provided for @transactionsListLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get transactionsListLastWeek;

  /// No description provided for @transactionsListOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get transactionsListOlder;

  /// No description provided for @transactionsSummaryBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get transactionsSummaryBalance;

  /// No description provided for @transactionsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get transactionsDialogCreateTitle;

  /// No description provided for @transactionsDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionsDialogEditTitle;

  /// No description provided for @transactionsValueExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionsValueExpense;

  /// No description provided for @transactionsValueIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsValueIncome;

  /// No description provided for @transactionsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionsFormCategory;

  /// No description provided for @transactionsFormNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get transactionsFormNotePlaceholder;

  /// No description provided for @transactionsFormIsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction'**
  String get transactionsFormIsRecurring;

  /// No description provided for @transactionsFormRecurringAria.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get transactionsFormRecurringAria;

  /// No description provided for @transactionsFeedbackRecurringFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction created. The recurring transaction could not be created.'**
  String get transactionsFeedbackRecurringFailed;

  /// No description provided for @recurringValueWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringValueWeekly;

  /// No description provided for @recurringValueMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringValueMonthly;

  /// No description provided for @recurringValueYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringValueYearly;

  /// No description provided for @recurringFeedbackValidatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} transaction validated} other {{count} transactions validated}}'**
  String recurringFeedbackValidatedCount(int count);

  /// No description provided for @recurringFeedbackValidationError.
  ///
  /// In en, this message translates to:
  /// **'Validation failed'**
  String get recurringFeedbackValidationError;

  /// No description provided for @recurringFeedbackSkipFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to skip'**
  String get recurringFeedbackSkipFailed;

  /// No description provided for @recurringFeedbackDeactivateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate'**
  String get recurringFeedbackDeactivateError;

  /// No description provided for @categoriesFeedbackSystemEditForbidden.
  ///
  /// In en, this message translates to:
  /// **'System categories cannot be edited'**
  String get categoriesFeedbackSystemEditForbidden;

  /// No description provided for @categoriesFeedbackSystemDeleteForbidden.
  ///
  /// In en, this message translates to:
  /// **'System categories cannot be deleted'**
  String get categoriesFeedbackSystemDeleteForbidden;

  /// No description provided for @accountsActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get accountsActionCreate;

  /// No description provided for @accountsActionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get accountsActionLater;

  /// No description provided for @accountsActionEnterRate.
  ///
  /// In en, this message translates to:
  /// **'Enter the rate'**
  String get accountsActionEnterRate;

  /// No description provided for @accountsListCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} account} other {{count} accounts}}'**
  String accountsListCount(int count);

  /// No description provided for @accountsDialogDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get accountsDialogDeleteMessage;

  /// No description provided for @accountsFormTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountsFormTypeTitle;

  /// No description provided for @accountsFormCustomisationTitle.
  ///
  /// In en, this message translates to:
  /// **'Customisation'**
  String get accountsFormCustomisationTitle;

  /// No description provided for @accountsFormDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get accountsFormDetailsTitle;

  /// No description provided for @accountsFormBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name (optional)'**
  String get accountsFormBankName;

  /// No description provided for @accountsFormBankNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. My bank'**
  String get accountsFormBankNamePlaceholder;

  /// No description provided for @accountsFormCustomLogo.
  ///
  /// In en, this message translates to:
  /// **'Custom logo (optional)'**
  String get accountsFormCustomLogo;

  /// No description provided for @accountsFormLogoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get accountsFormLogoCamera;

  /// No description provided for @accountsFormLogoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get accountsFormLogoGallery;

  /// No description provided for @accountsFormRateProposalTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing exchange rate'**
  String get accountsFormRateProposalTitle;

  /// No description provided for @accountsFormRateProposalMessage.
  ///
  /// In en, this message translates to:
  /// **'No {from} → {to} rate is defined.'**
  String accountsFormRateProposalMessage(String from, String to);

  /// No description provided for @accountsFormRateProposalHint.
  ///
  /// In en, this message translates to:
  /// **'Would you like to enter it now?'**
  String get accountsFormRateProposalHint;

  /// No description provided for @exchangeRatesDialogAddRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a rate'**
  String get exchangeRatesDialogAddRateTitle;

  /// No description provided for @recurringSummaryMonthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'~{amount} /month'**
  String recurringSummaryMonthlyExpenses(String amount);
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
