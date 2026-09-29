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

  /// No description provided for @budgetsFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get budgetsFormAmount;

  /// No description provided for @budgetsFormCurrencyAria.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get budgetsFormCurrencyAria;

  /// No description provided for @budgetsFormFrequencyAria.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get budgetsFormFrequencyAria;

  /// No description provided for @budgetsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetsFormCategory;

  /// No description provided for @budgetsFormCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get budgetsFormCategoryPlaceholder;

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

  /// No description provided for @subscriptionsDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription'**
  String get subscriptionsDialogDeleteTitle;

  /// No description provided for @subscriptionsDialogDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this subscription?'**
  String get subscriptionsDialogDeleteMessage;

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

  /// No description provided for @subscriptionsListNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String subscriptionsListNextRenewal(String date);

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

  /// No description provided for @subscriptionsDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get subscriptionsDetailHistory;

  /// No description provided for @subscriptionsDetailPaymentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} payment} other {{count} payments}}'**
  String subscriptionsDetailPaymentCount(int count);

  /// No description provided for @debtsFormPersonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get debtsFormPersonPlaceholder;

  /// No description provided for @debtsDialogDeleteFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete debt'**
  String get debtsDialogDeleteFormTitle;

  /// No description provided for @debtsDialogDeleteFormMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this debt?'**
  String get debtsDialogDeleteFormMessage;

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

  /// No description provided for @debtsDetailInitialAmount.
  ///
  /// In en, this message translates to:
  /// **'Initial amount'**
  String get debtsDetailInitialAmount;

  /// No description provided for @debtsDetailRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get debtsDetailRemainingAmount;

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

  /// No description provided for @debtsDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get debtsDetailProgress;

  /// No description provided for @debtsDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get debtsDetailDate;

  /// No description provided for @debtsFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get debtsFormCurrency;

  /// No description provided for @debtsFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get debtsFormAccount;

  /// No description provided for @debtsDetailAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get debtsDetailAccountDeleted;

  /// No description provided for @debtsFormDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get debtsFormDueDate;

  /// No description provided for @debtsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get debtsFormCategory;

  /// No description provided for @debtsDetailIncludedInBalance.
  ///
  /// In en, this message translates to:
  /// **'Included in balance'**
  String get debtsDetailIncludedInBalance;

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

  /// No description provided for @debtsDetailTotalRepaid.
  ///
  /// In en, this message translates to:
  /// **'Total repaid'**
  String get debtsDetailTotalRepaid;

  /// No description provided for @commonEmptyNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded'**
  String get commonEmptyNoPayments;

  /// No description provided for @debtsFeedbackPaymentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load payments'**
  String get debtsFeedbackPaymentsLoadError;

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

  /// No description provided for @debtsFormAccountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get debtsFormAccountPlaceholder;

  /// No description provided for @debtsFormAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Account required'**
  String get debtsFormAccountRequired;

  /// No description provided for @debtsFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get debtsFormAmount;

  /// No description provided for @debtsFormAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required'**
  String get debtsFormAmountRequired;

  /// No description provided for @debtsFeedbackAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get debtsFeedbackAmountInvalid;

  /// No description provided for @debtsFormAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum: {amount}'**
  String debtsFormAmountMax(String amount);

  /// No description provided for @debtsEmptyNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No active accounts. Create an account in settings.'**
  String get debtsEmptyNoAccounts;

  /// No description provided for @debtsFeedbackRepaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Repayment recorded'**
  String get debtsFeedbackRepaymentSaved;

  /// No description provided for @debtsFeedbackRepayError.
  ///
  /// In en, this message translates to:
  /// **'Repayment failed'**
  String get debtsFeedbackRepayError;

  /// No description provided for @debtsFormReminderDate.
  ///
  /// In en, this message translates to:
  /// **'Reminder date'**
  String get debtsFormReminderDate;

  /// No description provided for @debtsFormReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get debtsFormReminderTime;

  /// No description provided for @debtsDialogReminderDatePast.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be in the past'**
  String get debtsDialogReminderDatePast;

  /// No description provided for @debtsFeedbackSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed'**
  String get debtsFeedbackSnoozed;

  /// No description provided for @debtsFeedbackSnoozeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to snooze the reminder'**
  String get debtsFeedbackSnoozeError;

  /// No description provided for @debtsActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get debtsActionSnooze;

  /// No description provided for @commonValueYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonValueYes;

  /// No description provided for @commonValueNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonValueNo;

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

  /// No description provided for @budgetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budget for this period'**
  String get budgetsEmptyTitle;

  /// No description provided for @budgetsDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetsDialogDeleteTitle;

  /// No description provided for @budgetsDialogDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get budgetsDialogDeleteMessage;

  /// No description provided for @budgetsEmptyAllCategoriesBudgeted.
  ///
  /// In en, this message translates to:
  /// **'All categories already have a budget.'**
  String get budgetsEmptyAllCategoriesBudgeted;

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

  /// No description provided for @notificationsDialogDeleteAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications? This action is irreversible.'**
  String get notificationsDialogDeleteAllMessage;

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

  /// No description provided for @commonNavDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get commonNavDebts;

  /// No description provided for @commonNavSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get commonNavSubscriptions;

  /// No description provided for @debtsSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net balance'**
  String get debtsSummaryNet;

  /// No description provided for @debtsSummaryOutstandingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} outstanding} other {{count} outstanding}}'**
  String debtsSummaryOutstandingCount(int count);

  /// No description provided for @debtsSummaryLentTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} lent'**
  String debtsSummaryLentTotal(String amount);

  /// No description provided for @debtsSummaryBorrowedTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} borrowed'**
  String debtsSummaryBorrowedTotal(String amount);

  /// No description provided for @debtsListOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtsListOverdue;

  /// No description provided for @debtsListThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get debtsListThisWeek;

  /// No description provided for @debtsListThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get debtsListThisMonth;

  /// No description provided for @debtsListLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get debtsListLater;

  /// No description provided for @debtsListNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get debtsListNoDueDate;

  /// No description provided for @debtsListRepaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid'**
  String get debtsListRepaid;

  /// No description provided for @debtsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New debt'**
  String get debtsDialogCreateTitle;

  /// No description provided for @debtsDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit debt'**
  String get debtsDialogEditTitle;

  /// No description provided for @debtsDialogRepayTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get debtsDialogRepayTitle;

  /// No description provided for @debtsValueNotRepaid.
  ///
  /// In en, this message translates to:
  /// **'Not repaid'**
  String get debtsValueNotRepaid;

  /// No description provided for @debtsFormCurrencyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get debtsFormCurrencyPlaceholder;

  /// No description provided for @debtsFormReminderSummary.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {date} at {time}'**
  String debtsFormReminderSummary(String date, String time);

  /// No description provided for @debtsDetailReminderAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String debtsDetailReminderAt(String date, String time);

  /// No description provided for @debtsActionClearReminder.
  ///
  /// In en, this message translates to:
  /// **'Clear the reminder'**
  String get debtsActionClearReminder;

  /// No description provided for @subscriptionsSummaryMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get subscriptionsSummaryMonthlyTotal;

  /// No description provided for @subscriptionsSummaryActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} subscription} other {{count} subscriptions}}'**
  String subscriptionsSummaryActiveCount(int count);

  /// No description provided for @subscriptionsListActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} active} other {{count} active}}'**
  String subscriptionsListActiveCount(int count);

  /// No description provided for @subscriptionsListActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionsListActive;

  /// No description provided for @subscriptionsListInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get subscriptionsListInactive;

  /// No description provided for @subscriptionsValuePerWeek.
  ///
  /// In en, this message translates to:
  /// **'/week'**
  String get subscriptionsValuePerWeek;

  /// No description provided for @subscriptionsValueWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get subscriptionsValueWeekly;

  /// No description provided for @subscriptionsValueMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionsValueMonthly;

  /// No description provided for @subscriptionsValueYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionsValueYearly;

  /// No description provided for @subscriptionsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get subscriptionsDialogCreateTitle;

  /// No description provided for @subscriptionsDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get subscriptionsDialogEditTitle;

  /// No description provided for @subscriptionsFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get subscriptionsFormCategory;

  /// No description provided for @subscriptionsFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get subscriptionsFormCurrency;

  /// No description provided for @subscriptionsFormCurrencyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get subscriptionsFormCurrencyPlaceholder;

  /// No description provided for @subscriptionsDetailAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get subscriptionsDetailAmount;

  /// No description provided for @subscriptionsDetailStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get subscriptionsDetailStartDate;

  /// No description provided for @exchangeRatesValueEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get exchangeRatesValueEur;

  /// No description provided for @exchangeRatesValueXof.
  ///
  /// In en, this message translates to:
  /// **'CFA Franc (BCEAO)'**
  String get exchangeRatesValueXof;

  /// No description provided for @exchangeRatesValueUsd.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get exchangeRatesValueUsd;

  /// No description provided for @exchangeRatesValueGbp.
  ///
  /// In en, this message translates to:
  /// **'Pound Sterling'**
  String get exchangeRatesValueGbp;

  /// No description provided for @exchangeRatesValueChf.
  ///
  /// In en, this message translates to:
  /// **'Swiss Franc'**
  String get exchangeRatesValueChf;

  /// No description provided for @exchangeRatesValueCad.
  ///
  /// In en, this message translates to:
  /// **'Canadian Dollar'**
  String get exchangeRatesValueCad;

  /// No description provided for @exchangeRatesValueMad.
  ///
  /// In en, this message translates to:
  /// **'Moroccan Dirham'**
  String get exchangeRatesValueMad;

  /// No description provided for @budgetsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsPageTitle;

  /// No description provided for @budgetsPageUnbudgetedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbudgeted'**
  String get budgetsPageUnbudgetedTitle;

  /// No description provided for @budgetsDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetsDialogCreateTitle;

  /// No description provided for @budgetsActionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get budgetsActionDeactivate;

  /// No description provided for @budgetsEmptyNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get budgetsEmptyNoTransactions;

  /// No description provided for @budgetsListInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get budgetsListInactive;

  /// No description provided for @budgetsDetailOverBudget.
  ///
  /// In en, this message translates to:
  /// **'over {amount}'**
  String budgetsDetailOverBudget(String amount);

  /// No description provided for @budgetsDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String budgetsDetailRemaining(String amount);

  /// No description provided for @budgetsSummarySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSummarySpent;

  /// No description provided for @budgetsSummaryActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} budget} other {{count} budgets}}'**
  String budgetsSummaryActiveCount(int count);

  /// No description provided for @budgetsSummaryOverBudgetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} over budget} other {{count} over budget}}'**
  String budgetsSummaryOverBudgetCount(int count);

  /// No description provided for @budgetsSummaryExceededCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} budget exceeded} other {{count} budgets exceeded}}'**
  String budgetsSummaryExceededCount(int count);

  /// No description provided for @budgetsSummaryUnbudgeted.
  ///
  /// In en, this message translates to:
  /// **'{amount} unbudgeted'**
  String budgetsSummaryUnbudgeted(String amount);

  /// No description provided for @budgetsSummaryMonthlyInCurrency.
  ///
  /// In en, this message translates to:
  /// **'Monthly · in {currency}'**
  String budgetsSummaryMonthlyInCurrency(String currency);

  /// No description provided for @budgetsSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String budgetsSummaryTotal(String amount);

  /// No description provided for @budgetsValueWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetsValueWeekly;

  /// No description provided for @budgetsValueMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetsValueMonthly;

  /// No description provided for @budgetsValueYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetsValueYearly;

  /// No description provided for @dashboardPageRecentTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get dashboardPageRecentTransactionsTitle;

  /// No description provided for @dashboardSummaryGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'{hasName, select, yes {Good morning {name}} other {Good morning}}'**
  String dashboardSummaryGreetingMorning(String hasName, String name);

  /// No description provided for @dashboardSummaryGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'{hasName, select, yes {Good afternoon {name}} other {Good afternoon}}'**
  String dashboardSummaryGreetingAfternoon(String hasName, String name);

  /// No description provided for @dashboardSummaryGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'{hasName, select, yes {Good evening {name}} other {Good evening}}'**
  String dashboardSummaryGreetingEvening(String hasName, String name);

  /// No description provided for @dashboardSummaryMonthPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive month'**
  String get dashboardSummaryMonthPositive;

  /// No description provided for @dashboardSummaryMonthNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative month'**
  String get dashboardSummaryMonthNegative;

  /// No description provided for @dashboardSummaryMonthQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet month'**
  String get dashboardSummaryMonthQuiet;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start by creating an account\nto track your finances.'**
  String get dashboardEmptyMessage;

  /// No description provided for @recurringSummaryOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} expense overdue} other {{count} expenses overdue}}'**
  String recurringSummaryOverdueCount(int count);

  /// No description provided for @recurringActionValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get recurringActionValidate;

  /// No description provided for @recurringActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get recurringActionSkip;

  /// No description provided for @accountsSummaryNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Total net worth'**
  String get accountsSummaryNetWorth;

  /// No description provided for @exchangeRatesFeedbackConversionIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Some amounts could not be converted'**
  String get exchangeRatesFeedbackConversionIncompleteHint;

  /// No description provided for @transactionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get transactionsEmptyTitle;

  /// No description provided for @commonActionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonActionViewAll;

  /// No description provided for @commonNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get commonNavHome;

  /// No description provided for @commonNavTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get commonNavTransactions;

  /// No description provided for @commonNavBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get commonNavBudgets;

  /// No description provided for @commonActionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get commonActionDisable;

  /// No description provided for @settingsPageManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get settingsPageManagementTitle;

  /// No description provided for @settingsPageAdministrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get settingsPageAdministrationTitle;

  /// No description provided for @settingsPageAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsPageAppearanceTitle;

  /// No description provided for @settingsPageNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get settingsPageNavigationTitle;

  /// No description provided for @settingsPageNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsPageNotificationsTitle;

  /// No description provided for @settingsPageTimezoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsPageTimezoneTitle;

  /// No description provided for @settingsListAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts & Currencies'**
  String get settingsListAccounts;

  /// No description provided for @settingsListAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts and currencies'**
  String get settingsListAccountsHint;

  /// No description provided for @settingsListCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsListCategories;

  /// No description provided for @settingsListCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get settingsListCategoriesHint;

  /// No description provided for @settingsListTextScalePreview.
  ///
  /// In en, this message translates to:
  /// **'Here is a preview of the chosen text size.'**
  String get settingsListTextScalePreview;

  /// No description provided for @settingsListVersion.
  ///
  /// In en, this message translates to:
  /// **'K-Budget v{version}'**
  String settingsListVersion(String version);

  /// No description provided for @settingsFormTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsFormTheme;

  /// No description provided for @settingsFormTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsFormTextScale;

  /// No description provided for @settingsFormTimezoneHint.
  ///
  /// In en, this message translates to:
  /// **'Used for the day-before reminders'**
  String get settingsFormTimezoneHint;

  /// No description provided for @settingsValueThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsValueThemeLight;

  /// No description provided for @settingsValueThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsValueThemeDark;

  /// No description provided for @settingsValueThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsValueThemeAuto;

  /// No description provided for @settingsValueTextScaleSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsValueTextScaleSmall;

  /// No description provided for @settingsValueTextScaleMedium.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsValueTextScaleMedium;

  /// No description provided for @settingsValueTextScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsValueTextScaleLarge;

  /// No description provided for @settingsValueChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsValueChecking;

  /// No description provided for @settingsValueOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get settingsValueOnline;

  /// No description provided for @settingsValueOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get settingsValueOffline;

  /// No description provided for @settingsDialogDisableFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable {feature}?'**
  String settingsDialogDisableFeatureTitle(String feature);

  /// No description provided for @settingsDialogDisableFeatureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data will be hidden, not deleted.'**
  String get settingsDialogDisableFeatureMessage;

  /// No description provided for @settingsFeedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load preferences'**
  String get settingsFeedbackLoadError;

  /// No description provided for @settingsFeedbackSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save preferences'**
  String get settingsFeedbackSaveError;

  /// No description provided for @settingsPageDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsPageDataTitle;

  /// No description provided for @settingsFormDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get settingsFormDataSource;

  /// No description provided for @settingsValueDataSourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get settingsValueDataSourceLocal;

  /// No description provided for @settingsValueDataSourceServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsValueDataSourceServer;

  /// No description provided for @settingsFormServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsFormServerUrl;

  /// No description provided for @settingsFormServerUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'The server URL is required'**
  String get settingsFormServerUrlRequired;

  /// No description provided for @settingsFormServerUrlHttpsRequired.
  ///
  /// In en, this message translates to:
  /// **'The URL must start with https://'**
  String get settingsFormServerUrlHttpsRequired;

  /// No description provided for @settingsFeedbackServerUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'URL saved'**
  String get settingsFeedbackServerUrlSaved;

  /// No description provided for @settingsFeedbackServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get settingsFeedbackServerUnreachable;

  /// No description provided for @settingsFeedbackServerTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out'**
  String get settingsFeedbackServerTimeout;

  /// No description provided for @settingsFeedbackServerAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied by the server'**
  String get settingsFeedbackServerAccessDenied;

  /// No description provided for @settingsFeedbackServerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Endpoint not found — check the URL'**
  String get settingsFeedbackServerNotFound;

  /// No description provided for @settingsDialogChangeDataSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Change data source?'**
  String get settingsDialogChangeDataSourceTitle;

  /// No description provided for @settingsDialogChangeDataSourceMessage.
  ///
  /// In en, this message translates to:
  /// **'Data sources are independent. The data of the current source will not be visible after the change.\n\nThe app will restart to apply the new source.'**
  String get settingsDialogChangeDataSourceMessage;

  /// No description provided for @notificationsValueSubscriptionDue.
  ///
  /// In en, this message translates to:
  /// **'Subscription due'**
  String get notificationsValueSubscriptionDue;

  /// No description provided for @notificationsValueDebtDue.
  ///
  /// In en, this message translates to:
  /// **'Debt due'**
  String get notificationsValueDebtDue;

  /// No description provided for @notificationsValueDebtReminder.
  ///
  /// In en, this message translates to:
  /// **'Debt reminder'**
  String get notificationsValueDebtReminder;

  /// No description provided for @notificationsValueRecurringTransactionDue.
  ///
  /// In en, this message translates to:
  /// **'Recurring transaction due'**
  String get notificationsValueRecurringTransactionDue;

  /// No description provided for @notificationsValueBudgetThreshold.
  ///
  /// In en, this message translates to:
  /// **'Budget threshold reached'**
  String get notificationsValueBudgetThreshold;

  /// No description provided for @notificationsValueBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get notificationsValueBudgetExceeded;

  /// No description provided for @usersListProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get usersListProfile;

  /// No description provided for @usersListProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Profile, security, sign out'**
  String get usersListProfileHint;

  /// No description provided for @usersListManageHint.
  ///
  /// In en, this message translates to:
  /// **'Invitations and access management'**
  String get usersListManageHint;

  /// No description provided for @usersListChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get usersListChangePassword;

  /// No description provided for @usersListExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export my data (JSON)'**
  String get usersListExportJson;

  /// No description provided for @usersListExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export my transactions (CSV)'**
  String get usersListExportCsv;

  /// No description provided for @usersPageAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersPageAdminTitle;

  /// No description provided for @usersPageProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get usersPageProfileTitle;

  /// No description provided for @usersPageIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get usersPageIdentityTitle;

  /// No description provided for @usersPageSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get usersPageSecurityTitle;

  /// No description provided for @usersPageDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get usersPageDataTitle;

  /// No description provided for @usersPageDangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get usersPageDangerZoneTitle;

  /// No description provided for @usersFormEmailManagedHint.
  ///
  /// In en, this message translates to:
  /// **'Managed by the admin'**
  String get usersFormEmailManagedHint;

  /// No description provided for @usersFormCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get usersFormCurrentPassword;

  /// No description provided for @usersFormNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get usersFormNewPassword;

  /// No description provided for @usersFormConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm the new password'**
  String get usersFormConfirmNewPassword;

  /// No description provided for @usersFormPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get usersFormPasswordMismatch;

  /// No description provided for @usersFormDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand that this action is permanent'**
  String get usersFormDeleteAccountConfirm;

  /// No description provided for @usersValueNameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get usersValueNameNotSet;

  /// No description provided for @usersActionDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get usersActionDeleteAccount;

  /// No description provided for @usersActionChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get usersActionChangePhoto;

  /// No description provided for @usersActionDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get usersActionDeletePhoto;

  /// No description provided for @usersActionEditPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit photo'**
  String get usersActionEditPhoto;

  /// No description provided for @usersDialogDeleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deactivated. You will no longer be able to sign in with these credentials. Your data is kept in the database for traceability.'**
  String get usersDialogDeleteAccountMessage;

  /// No description provided for @usersFeedbackProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the profile'**
  String get usersFeedbackProfileLoadError;

  /// No description provided for @usersFeedbackNameSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the name. Please try again.'**
  String get usersFeedbackNameSaveError;

  /// No description provided for @usersFeedbackExportJsonError.
  ///
  /// In en, this message translates to:
  /// **'Error during the JSON export. Please try again.'**
  String get usersFeedbackExportJsonError;

  /// No description provided for @usersFeedbackExportCsvError.
  ///
  /// In en, this message translates to:
  /// **'Error during the CSV export. Please try again.'**
  String get usersFeedbackExportCsvError;

  /// No description provided for @usersFeedbackDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get usersFeedbackDownloading;

  /// No description provided for @usersFeedbackAvatarUploadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload the photo. Please try again.'**
  String get usersFeedbackAvatarUploadError;

  /// No description provided for @usersFeedbackPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get usersFeedbackPasswordChanged;

  /// No description provided for @usersFeedbackPasswordChangeError.
  ///
  /// In en, this message translates to:
  /// **'Unable to change the password'**
  String get usersFeedbackPasswordChangeError;

  /// No description provided for @usersFeedbackDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Error during deletion. Please try again.'**
  String get usersFeedbackDeleteAccountError;

  /// No description provided for @errorsApiFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large. The maximum size is 2 MB.'**
  String get errorsApiFileTooLarge;

  /// No description provided for @errorsApiInvalidImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Only JPG and PNG formats are accepted.'**
  String get errorsApiInvalidImageFormat;

  /// No description provided for @commonActionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonActionEnable;

  /// No description provided for @authFormEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authFormEmailAddress;

  /// No description provided for @usersPageInvitationsTab.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get usersPageInvitationsTab;

  /// No description provided for @usersActionInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite a user'**
  String get usersActionInvite;

  /// No description provided for @usersActionCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Create and copy the link'**
  String get usersActionCreateInvite;

  /// No description provided for @usersActionCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy the link'**
  String get usersActionCopyLink;

  /// No description provided for @usersActionRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get usersActionRevoke;

  /// No description provided for @usersEmptyInvitations.
  ///
  /// In en, this message translates to:
  /// **'No invitations yet'**
  String get usersEmptyInvitations;

  /// No description provided for @usersEmptyUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get usersEmptyUsers;

  /// No description provided for @usersFormEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'new@example.com'**
  String get usersFormEmailPlaceholder;

  /// No description provided for @usersListInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'By {email}'**
  String usersListInvitedBy(String email);

  /// No description provided for @usersValueAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get usersValueAdmin;

  /// No description provided for @usersValueInvitationActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get usersValueInvitationActive;

  /// No description provided for @usersValueInvitationExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get usersValueInvitationExpired;

  /// No description provided for @usersValueInvitationUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usersValueInvitationUsed;

  /// No description provided for @usersValueInvitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get usersValueInvitationRevoked;

  /// No description provided for @usersFeedbackLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to the clipboard.'**
  String get usersFeedbackLinkCopied;

  /// No description provided for @usersFeedbackInviteCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created and link copied to the clipboard.'**
  String get usersFeedbackInviteCreated;

  /// No description provided for @usersFeedbackInviteCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the invitation.'**
  String get usersFeedbackInviteCreateError;

  /// No description provided for @usersFeedbackInviteRevokeError.
  ///
  /// In en, this message translates to:
  /// **'Unable to revoke the invitation.'**
  String get usersFeedbackInviteRevokeError;

  /// No description provided for @usersFeedbackLoadUsersError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load users.'**
  String get usersFeedbackLoadUsersError;

  /// No description provided for @usersFeedbackLoadInvitationsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load invitations.'**
  String get usersFeedbackLoadInvitationsError;

  /// No description provided for @usersFeedbackUserDisableError.
  ///
  /// In en, this message translates to:
  /// **'Unable to disable the user.'**
  String get usersFeedbackUserDisableError;

  /// No description provided for @usersFeedbackUserEnableError.
  ///
  /// In en, this message translates to:
  /// **'Unable to re-enable the user.'**
  String get usersFeedbackUserEnableError;

  /// No description provided for @exchangeRatesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Currencies & Rates'**
  String get exchangeRatesPageTitle;

  /// No description provided for @exchangeRatesPageCurrenciesTitle.
  ///
  /// In en, this message translates to:
  /// **'My currencies'**
  String get exchangeRatesPageCurrenciesTitle;

  /// No description provided for @exchangeRatesPageRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversion rates'**
  String get exchangeRatesPageRatesTitle;

  /// No description provided for @exchangeRatesPageCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get exchangeRatesPageCalculatorTitle;

  /// No description provided for @exchangeRatesDialogEditRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the rate'**
  String get exchangeRatesDialogEditRateTitle;

  /// No description provided for @exchangeRatesDialogAddCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a currency'**
  String get exchangeRatesDialogAddCurrencyTitle;

  /// No description provided for @exchangeRatesDialogDeleteRateMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the rate {baseCurrency} → {targetCurrency}?'**
  String exchangeRatesDialogDeleteRateMessage(
    String baseCurrency,
    String targetCurrency,
  );

  /// No description provided for @exchangeRatesDialogRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {currency}?'**
  String exchangeRatesDialogRemoveTitle(String currency);

  /// No description provided for @exchangeRatesDialogRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The currency {currency} is used by existing accounts. Remove anyway?'**
  String exchangeRatesDialogRemoveMessage(String currency);

  /// No description provided for @exchangeRatesDialogRemoveUnusedMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {currency} from your currencies?'**
  String exchangeRatesDialogRemoveUnusedMessage(String currency);

  /// No description provided for @exchangeRatesActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get exchangeRatesActionRemove;

  /// No description provided for @exchangeRatesActionRemoveCurrencyAria.
  ///
  /// In en, this message translates to:
  /// **'Remove this currency'**
  String get exchangeRatesActionRemoveCurrencyAria;

  /// No description provided for @exchangeRatesValuePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get exchangeRatesValuePrimary;

  /// No description provided for @exchangeRatesValueCalculatedRate.
  ///
  /// In en, this message translates to:
  /// **'Rate: 1 {from} = {rate} {to}'**
  String exchangeRatesValueCalculatedRate(String from, String rate, String to);

  /// No description provided for @exchangeRatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rates configured'**
  String get exchangeRatesEmptyTitle;

  /// No description provided for @exchangeRatesEmptyCalculator.
  ///
  /// In en, this message translates to:
  /// **'Enter two amounts to calculate the rate'**
  String get exchangeRatesEmptyCalculator;

  /// No description provided for @exchangeRatesFeedbackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load exchange rates'**
  String get exchangeRatesFeedbackLoadError;

  /// No description provided for @exchangeRatesFeedbackSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving the rate.'**
  String get exchangeRatesFeedbackSaveError;

  /// No description provided for @exchangeRatesFormBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get exchangeRatesFormBaseCurrency;

  /// No description provided for @exchangeRatesFormTargetCurrency.
  ///
  /// In en, this message translates to:
  /// **'Target currency'**
  String get exchangeRatesFormTargetCurrency;

  /// No description provided for @exchangeRatesFormCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get exchangeRatesFormCurrency;

  /// No description provided for @exchangeRatesFormCalculatorFrom.
  ///
  /// In en, this message translates to:
  /// **'I have'**
  String get exchangeRatesFormCalculatorFrom;

  /// No description provided for @exchangeRatesFormRateWithPair.
  ///
  /// In en, this message translates to:
  /// **'Rate (1 {base} = X {target})'**
  String exchangeRatesFormRateWithPair(String base, String target);

  /// No description provided for @exchangeRatesFormRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid rate (> 0).'**
  String get exchangeRatesFormRateInvalid;

  /// No description provided for @exchangeRatesFormRatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 655.957'**
  String get exchangeRatesFormRatePlaceholder;

  /// No description provided for @transactionsValueTransferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer to {account}'**
  String transactionsValueTransferTo(String account);

  /// No description provided for @transactionsValueTransferFrom.
  ///
  /// In en, this message translates to:
  /// **'Transfer from {account}'**
  String transactionsValueTransferFrom(String account);

  /// No description provided for @transactionsValueBalanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get transactionsValueBalanceAdjustment;

  /// No description provided for @debtsValueRepayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment - {person}'**
  String debtsValueRepayment(String person);

  /// No description provided for @accountsValueDefaultAccountName.
  ///
  /// In en, this message translates to:
  /// **'Main account'**
  String get accountsValueDefaultAccountName;
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
