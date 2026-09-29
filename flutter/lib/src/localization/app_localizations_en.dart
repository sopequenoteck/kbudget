// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonActionCancel => 'Cancel';

  @override
  String get commonActionSave => 'Save';

  @override
  String get commonActionDelete => 'Delete';

  @override
  String get commonActionEdit => 'Edit';

  @override
  String get commonActionRetry => 'Retry';

  @override
  String get errorsClientGeneric => 'An error occurred';

  @override
  String get errorsClientNetwork => 'Unable to reach the server';

  @override
  String get errorsClientUnknown => 'Unknown error';

  @override
  String get errorsApiBadRequest => 'The request could not be processed.';

  @override
  String get errorsApiValidationError =>
      'Please check the information you entered.';

  @override
  String get errorsApiMalformedRequest => 'Invalid request.';

  @override
  String get errorsApiPasswordIncorrect => 'Incorrect password.';

  @override
  String get usersFeedbackCurrentPasswordIncorrect =>
      'Current password incorrect.';

  @override
  String get usersFeedbackLastAdminDeletionForbidden =>
      'You are the last administrator. Please appoint another administrator before deleting your account.';

  @override
  String get errorsApiPasswordUnchanged =>
      'The new password must be different from the current one.';

  @override
  String get errorsApiConfirmationRequired => 'Explicit confirmation required.';

  @override
  String get errorsApiUnauthenticated => 'Authentication required.';

  @override
  String get errorsApiTokenExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorsApiTokenRevoked =>
      'Your session has been revoked. Please sign in again.';

  @override
  String get errorsApiTokenReuseDetected =>
      'Session interrupted for security reasons. Please sign in again.';

  @override
  String get errorsApiTokenInvalid => 'Invalid session. Please sign in again.';

  @override
  String get errorsApiAccessDenied => 'Access denied';

  @override
  String get errorsApiPasswordResetRequired => 'Credentials reset required';

  @override
  String get errorsApiPasswordResetNotRequired =>
      'Credentials reset is not required for this account.';

  @override
  String get errorsApiFeatureDisabled => 'Feature disabled';

  @override
  String get errorsApiLastAdminDeletionForbidden =>
      'At least one active administrator must exist.';

  @override
  String get errorsApiNotFound => 'Resource not found';

  @override
  String get errorsApiConflict => 'Data conflict';

  @override
  String get errorsApiLastAdminCannotBeDisabled =>
      'The last active administrator cannot be disabled.';

  @override
  String get errorsApiEmailAlreadyExists => 'Email already in use';

  @override
  String get errorsApiTooManyRequests =>
      'Too many attempts. Please try again shortly.';

  @override
  String get errorsApiInternalError => 'An internal error occurred';

  @override
  String get budgetsFormAmount => 'Amount';

  @override
  String get budgetsFormCurrencyAria => 'Currency';

  @override
  String get budgetsFormFrequencyAria => 'Frequency';

  @override
  String get budgetsFormCategory => 'Category';

  @override
  String get budgetsFormCategoryPlaceholder => 'Choose a category';

  @override
  String get budgetsFormThresholdAria => 'Alert threshold';

  @override
  String get authFeedbackInvalidCredentials => 'Incorrect email or password';

  @override
  String transactionsEmptyNoneInMonth(String month) {
    return 'No transactions in $month';
  }

  @override
  String get transactionsListNoCategory => 'No category';

  @override
  String get transactionsFormDescriptionPlaceholder => 'Description';

  @override
  String get transactionsFormAccount => 'Account';

  @override
  String get transactionsDialogDeleteTitle => 'Delete transaction';

  @override
  String get transactionsDialogDeleteMessage =>
      'Are you sure you want to delete this transaction?';

  @override
  String get subscriptionsFormNamePlaceholder => 'Name';

  @override
  String get subscriptionsFormAccount => 'Account';

  @override
  String get commonValueActive => 'Active';

  @override
  String get subscriptionsDialogDeleteTitle => 'Delete subscription';

  @override
  String get subscriptionsDialogDeleteMessage =>
      'Are you sure you want to delete this subscription?';

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions';

  @override
  String get subscriptionsValuePerMonth => '/month';

  @override
  String get subscriptionsValuePerYear => '/year';

  @override
  String subscriptionsListNextRenewal(String date) {
    return 'Next: $date';
  }

  @override
  String get commonValueInactive => 'Inactive';

  @override
  String get subscriptionsActionPay => 'Pay';

  @override
  String get subscriptionsFeedbackPaid => 'Payment recorded';

  @override
  String get subscriptionsDetailHistory => 'History';

  @override
  String subscriptionsDetailPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '$count payment',
    );
    return '$_temp0';
  }

  @override
  String get debtsFormPersonPlaceholder => 'Person';

  @override
  String get debtsDialogDeleteFormTitle => 'Delete debt';

  @override
  String get debtsDialogDeleteFormMessage =>
      'Are you sure you want to delete this debt?';

  @override
  String get debtsEmptyTitle => 'No debts';

  @override
  String get debtsValueRepaid => 'Repaid';

  @override
  String get debtsDetailInitialAmount => 'Initial amount';

  @override
  String get debtsDetailRemainingAmount => 'Remaining amount';

  @override
  String get debtsActionRepay => 'Repay';

  @override
  String get debtsDialogSnoozeTitle => 'Snooze the reminder';

  @override
  String get debtsDetailProgress => 'Progress';

  @override
  String get debtsDetailDate => 'Date';

  @override
  String get debtsFormCurrency => 'Currency';

  @override
  String get debtsFormAccount => 'Account';

  @override
  String get debtsDetailAccountDeleted => 'Account deleted';

  @override
  String get debtsFormDueDate => 'Due date';

  @override
  String get debtsFormCategory => 'Category';

  @override
  String get debtsDetailIncludedInBalance => 'Included in balance';

  @override
  String get debtsFormReminderAria => 'Reminder';

  @override
  String get debtsDetailPayments => 'Payments';

  @override
  String get debtsDetailTotalRepaid => 'Total repaid';

  @override
  String get commonEmptyNoPayments => 'No payments recorded';

  @override
  String get debtsFeedbackPaymentsLoadError => 'Unable to load payments';

  @override
  String get debtsValueBorrowed => 'Borrowed';

  @override
  String get debtsValueLent => 'Lent';

  @override
  String get debtsFormAccountPlaceholder => 'Select an account';

  @override
  String get debtsFormAccountRequired => 'Account required';

  @override
  String get debtsFormAmount => 'Amount';

  @override
  String get debtsFormAmountRequired => 'Amount required';

  @override
  String get debtsFeedbackAmountInvalid => 'Invalid amount';

  @override
  String debtsFormAmountMax(String amount) {
    return 'Maximum: $amount';
  }

  @override
  String get debtsEmptyNoAccounts =>
      'No active accounts. Create an account in settings.';

  @override
  String get debtsFeedbackRepaymentSaved => 'Repayment recorded';

  @override
  String get debtsFeedbackRepayError => 'Repayment failed';

  @override
  String get debtsFormReminderDate => 'Reminder date';

  @override
  String get debtsFormReminderTime => 'Reminder time';

  @override
  String get debtsDialogReminderDatePast => 'The date cannot be in the past';

  @override
  String get debtsFeedbackSnoozed => 'Reminder snoozed';

  @override
  String get debtsFeedbackSnoozeError => 'Failed to snooze the reminder';

  @override
  String get debtsActionSnooze => 'Snooze';

  @override
  String get commonValueYes => 'Yes';

  @override
  String get commonValueNo => 'No';

  @override
  String get transactionsFormTransferFromPlaceholder => 'Source account';

  @override
  String get transactionsFormTransferToPlaceholder => 'Destination account';

  @override
  String get transactionsFormAmount => 'Amount';

  @override
  String get transactionsFormNoteAria => 'Note';

  @override
  String get transactionsActionTransferSubmit => 'Make the transfer';

  @override
  String get transactionsFormTransferAccountsMismatch =>
      'The source and destination accounts must be different';

  @override
  String get commonValidationRequired => 'This field is required.';

  @override
  String get commonValidationAmountPositive =>
      'The amount must be greater than 0';

  @override
  String commonValidationMaxLength(int max) {
    return '$max characters maximum';
  }

  @override
  String get accountsPageTitle => 'Accounts';

  @override
  String get accountsEmptyTitle => 'No accounts';

  @override
  String get accountsDialogCreateTitle => 'New account';

  @override
  String get accountsDialogEditTitle => 'Edit account';

  @override
  String get accountsValueCurrent => 'Current account';

  @override
  String get accountsValueSavings => 'Savings';

  @override
  String get accountsValueCash => 'Cash';

  @override
  String get accountsFormName => 'Account name';

  @override
  String get accountsFormOpeningBalance => 'Opening balance';

  @override
  String get accountsFormCurrency => 'Currency';

  @override
  String get accountsFormIcon => 'Icon';

  @override
  String get commonFormColour => 'Colour';

  @override
  String get accountsFormActiveHint =>
      'Set another default account before deactivating this one';

  @override
  String get accountsFormCurrentBalance => 'Current balance';

  @override
  String get accountsFormNewBalance => 'New balance';

  @override
  String get accountsFormPreviewPlaceholder => 'Account preview';

  @override
  String get accountsValueDefault => 'Default';

  @override
  String get accountsDialogDeleteTitle => 'Delete account';

  @override
  String get accountsDialogDeleteWarningMessage =>
      'Are you sure you want to delete this account? This action is irreversible.';

  @override
  String get accountsFeedbackLoadError => 'Error loading accounts';

  @override
  String get categoriesPageTitle => 'Categories';

  @override
  String get categoriesEmptyNoCategories => 'No categories';

  @override
  String get categoriesDialogCreateTitle => 'New category';

  @override
  String get categoriesDialogEditTitle => 'Edit category';

  @override
  String get categoriesFormName => 'Name';

  @override
  String get categoriesFormIcon => 'Icon';

  @override
  String get commonValidationNameRequired => 'Name required';

  @override
  String get categoriesFormNameMaxLength => '30 characters maximum';

  @override
  String get categoriesFormNameDuplicate => 'This category name already exists';

  @override
  String get categoriesFormIconRequired => 'Icon is required';

  @override
  String get categoriesDialogDeleteTitle => 'Delete category';

  @override
  String get categoriesDialogDeleteMessage =>
      'This category will be unlinked from all related items.';

  @override
  String get budgetsEmptyTitle => 'No budget for this period';

  @override
  String get budgetsDialogDeleteTitle => 'Delete budget';

  @override
  String get budgetsDialogDeleteMessage =>
      'Are you sure you want to delete this budget?';

  @override
  String get budgetsEmptyAllCategoriesBudgeted =>
      'All categories already have a budget.';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notificationsActionMarkAllReadHint => 'Mark all as read';

  @override
  String get notificationsActionDeleteAllHint => 'Clear history';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsDialogDeleteAllMessage =>
      'Delete all notifications? This action is irreversible.';

  @override
  String get debtsFeedbackLoadError => 'Unable to load debt';

  @override
  String get commonValueToday => 'Today';

  @override
  String get commonValueYesterday => 'Yesterday';

  @override
  String get recurringPageTitle => 'Recurring';

  @override
  String get recurringValueOverdue => 'Overdue';

  @override
  String get recurringValueUpcoming => 'Upcoming';

  @override
  String get recurringActionMarkAsPaid => 'Mark as paid';

  @override
  String get recurringActionSkipOccurrence => 'Skip this occurrence';

  @override
  String get recurringActionDeactivate =>
      'Deactivate the recurring transaction';

  @override
  String get recurringActionPayAll => 'All paid';

  @override
  String recurringDetailNext(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringSummaryTitle => 'Monthly summary';

  @override
  String recurringSummaryExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '$count expense',
    );
    return '$_temp0';
  }

  @override
  String get recurringEmptyTitle => 'No recurring transactions';

  @override
  String get recurringFeedbackValidatedOne => 'Transaction validated';

  @override
  String get recurringFeedbackSkipped => 'Occurrence skipped';

  @override
  String get recurringFeedbackDeactivated =>
      'Recurring transaction deactivated';

  @override
  String get authPageLoginTagline => 'Sign in to your account';

  @override
  String get authFormEmailRequired => 'Email required';

  @override
  String get authFormPasswordRequired => 'Password required';

  @override
  String get authPageFirstLoginTitle => 'First sign-in';

  @override
  String get authPageFirstLoginNotice =>
      'You are signed in with the initial credentials generated by the system. Set your final email, a personal password and your display name now to access the application.';

  @override
  String get authFormDisplayNameRequired =>
      'Name required (100 characters max)';

  @override
  String get authFeedbackResetError =>
      'Error updating your credentials. Please try again.';

  @override
  String get authFormPasswordConfirmRequired => 'Please confirm your password';

  @override
  String get authFeedbackInvalidLink =>
      'Invalid, expired, already used or revoked link.';

  @override
  String get authFeedbackCreateAccountError =>
      'Error creating the account. Please try again.';

  @override
  String get authFeedbackCheckingLink => 'Checking the link...';

  @override
  String get authPageInvalidLinkTitle => 'Invalid link';

  @override
  String get authActionBackToLogin => 'Back to sign-in';

  @override
  String get authPageAcceptInviteTitle => 'Create your account';

  @override
  String get authPageAcceptInviteTagline =>
      'A few details to finish signing up';

  @override
  String get authFormEmail => 'Email';

  @override
  String get authFormEmailInvalid => 'Invalid email';

  @override
  String get authFormPassword => 'Password';

  @override
  String get authFormDisplayName => 'Display name';

  @override
  String get authFormConfirmPassword => 'Confirm password';

  @override
  String get authFormPasswordMismatch => 'Passwords do not match';

  @override
  String get authFormCurrency => 'Currency';

  @override
  String get authActionCreateAccount => 'Create my account';

  @override
  String get authActionSignIn => 'Sign in';

  @override
  String authFormPasswordMinLength(int min) {
    return '$min characters minimum';
  }

  @override
  String get authActionUnlockBiometricReason => 'Unlock K-Budget';

  @override
  String get authFeedbackBiometricError => 'Biometric error. Use your PIN.';

  @override
  String get authFormPinMinLength => 'The PIN must contain at least 4 digits';

  @override
  String get authFeedbackPinIncorrect => 'Incorrect PIN';

  @override
  String get authDialogForgotPinTitle => 'Forgot your PIN?';

  @override
  String get authDialogForgotPinServerMessage =>
      'You will be signed out and will need to sign in again with your credentials.';

  @override
  String get authDialogForgotPinLocalMessage =>
      'In local mode, resetting the PIN will erase all your data. This action is irreversible.';

  @override
  String get authPagePinTagline => 'Enter your PIN to continue';

  @override
  String get authActionUnlock => 'Unlock';

  @override
  String get authActionBiometric => 'Biometrics';

  @override
  String get commonActionConfirm => 'Confirm';

  @override
  String get commonActionClose => 'Close';

  @override
  String get commonActionChooseEmoji => 'Choose an emoji';

  @override
  String get commonFormEmojiSearchPlaceholder => 'Search for an emoji…';

  @override
  String get commonEmptyNoRecentEmoji => 'No recent emoji';

  @override
  String get transactionsActionCreate => 'Transaction';

  @override
  String get subscriptionsActionCreate => 'Subscription';

  @override
  String get debtsActionCreate => 'Debt';

  @override
  String get budgetsActionCreate => 'Budget';

  @override
  String get transactionsActionTransfer => 'Transfer';

  @override
  String get commonActionPreviousMonthAria => 'Previous month';

  @override
  String get commonActionNextMonthAria => 'Next month';

  @override
  String get commonNavSettings => 'Settings';

  @override
  String get commonActionLogout => 'Sign out';

  @override
  String get commonActionReset => 'Reset';

  @override
  String get commonFormSearchPlaceholder => 'Search...';

  @override
  String get commonFormSelectPlaceholder => 'Select...';

  @override
  String get commonEmptyNoResults => 'No results';

  @override
  String categoriesActionCreateNamed(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get categoriesFormSearchPlaceholder => 'Search for a category…';

  @override
  String get categoriesEmptyTitle => 'No categories yet — create one';

  @override
  String get categoriesActionCreate => 'Create';

  @override
  String get categoriesListNoResults => 'No categories found';

  @override
  String get commonActionBack => 'Back';

  @override
  String get accountsFormSelectBankPlaceholder => 'Select a bank';

  @override
  String get accountsFormBankTitle => 'Bank';

  @override
  String get accountsValueOtherCustom => 'Other / Custom';

  @override
  String get accountsFilterBankSearchPlaceholder => 'Search for a bank…';

  @override
  String get accountsFeedbackBanksLoadError => 'Unable to load banks';

  @override
  String get accountsEmptyBankNotFound => 'No bank found';

  @override
  String get accountsListBankGroupFrance => 'France';

  @override
  String get accountsListBankGroupWestAfrica => 'West Africa';

  @override
  String get accountsListBankGroupInternational => 'International';

  @override
  String get commonFeedbackSaveError => 'Save failed';

  @override
  String get commonFeedbackDeleteError => 'Delete failed';

  @override
  String get commonFeedbackLoadError => 'Loading error';

  @override
  String get onboardingDialogSwitchToLocalTitle => 'Switch to local mode?';

  @override
  String get onboardingDialogSwitchToLocalMessage =>
      'Your data will be stored only on this device. You can switch back to server mode from settings.';

  @override
  String get onboardingActionUseLocalMode => 'Use in local mode';

  @override
  String get onboardingPageTitle => 'Welcome to K-Budget';

  @override
  String get onboardingPageTagline => 'Choose your data mode';

  @override
  String get onboardingValueLocalMode => 'Local mode';

  @override
  String get onboardingValueLocalModeHint => 'Your data stays on this device';

  @override
  String get onboardingValueServerMode => 'Server mode';

  @override
  String get onboardingValueServerModeHint => 'Sync with your K-Budget server';

  @override
  String get onboardingPageServerSetupTitle => 'Server setup';

  @override
  String get onboardingFormServerUrlHint => 'Enter your K-Budget server URL';

  @override
  String get onboardingFormServerUrl => 'Server URL';

  @override
  String get onboardingFormServerUrlRequired => 'The URL is required';

  @override
  String get onboardingFormServerUrlInvalid => 'Invalid URL';

  @override
  String get onboardingFeedbackConnected => 'Connected successfully';

  @override
  String get onboardingFeedbackConnecting => 'Connecting…';

  @override
  String get onboardingActionCheckConnection => 'Check connection';

  @override
  String get compatibilityPageClientTitle => 'App update required';

  @override
  String get compatibilityPageServerTitle => 'Server update required';

  @override
  String get compatibilityPageTagline =>
      'This version of the application and your server cannot work together.';

  @override
  String get compatibilityFeedbackOffline =>
      'Server unreachable. Check the URL and your connection.';

  @override
  String compatibilityFeedbackServerTooOldUnknown(String requiredVersion) {
    return 'This server is too old to report its version. This application requires at least version $requiredVersion. Update your instance, then restart the application.';
  }

  @override
  String compatibilityFeedbackServerTooOldVersion(
    String serverVersion,
    String requiredVersion,
  ) {
    return 'This server is running version $serverVersion. This application requires at least version $requiredVersion. Update your instance, then restart the application.';
  }

  @override
  String compatibilityFeedbackClientTooOld(String requiredVersion) {
    return 'This server requires at least version $requiredVersion of the application. Update K-Budget from your app store.';
  }

  @override
  String compatibilityFeedbackClientTooOldVerbose(
    String requiredVersion,
    String clientVersion,
  ) {
    return 'This server requires at least version $requiredVersion of the application. You are using version $clientVersion. Update K-Budget from your app store.';
  }

  @override
  String get commonValueTomorrow => 'Tomorrow';

  @override
  String commonValueDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String commonValueWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '$count week ago',
    );
    return '$_temp0';
  }

  @override
  String commonValueDaysAgoShort(int count) {
    return '${count}d ago';
  }

  @override
  String commonValueInDaysShort(int count) {
    return 'in ${count}d';
  }

  @override
  String dashboardSummaryMonthVariation(String amount) {
    return '$amount this month';
  }

  @override
  String get transactionsPageTitle => 'Transactions';

  @override
  String get transactionsListThisWeek => 'This week';

  @override
  String get transactionsListLastWeek => 'Last week';

  @override
  String get transactionsListOlder => 'Older';

  @override
  String get transactionsSummaryBalance => 'Balance';

  @override
  String get transactionsDialogCreateTitle => 'New transaction';

  @override
  String get transactionsDialogEditTitle => 'Edit transaction';

  @override
  String get transactionsValueExpense => 'Expense';

  @override
  String get transactionsValueIncome => 'Income';

  @override
  String get transactionsFormCategory => 'Category';

  @override
  String get transactionsFormNotePlaceholder => 'Add a note…';

  @override
  String get transactionsFormIsRecurring => 'Recurring transaction';

  @override
  String get transactionsFormRecurringAria => 'Recurring';

  @override
  String get transactionsFeedbackRecurringFailed =>
      'Transaction created. The recurring transaction could not be created.';

  @override
  String get recurringValueWeekly => 'Weekly';

  @override
  String get recurringValueMonthly => 'Monthly';

  @override
  String get recurringValueYearly => 'Yearly';

  @override
  String recurringFeedbackValidatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions validated',
      one: '$count transaction validated',
    );
    return '$_temp0';
  }

  @override
  String get recurringFeedbackValidationError => 'Validation failed';

  @override
  String get recurringFeedbackSkipFailed => 'Failed to skip';

  @override
  String get recurringFeedbackDeactivateError => 'Failed to deactivate';

  @override
  String get categoriesFeedbackSystemEditForbidden =>
      'System categories cannot be edited';

  @override
  String get categoriesFeedbackSystemDeleteForbidden =>
      'System categories cannot be deleted';

  @override
  String get accountsActionCreate => 'Create an account';

  @override
  String get accountsActionLater => 'Later';

  @override
  String get accountsActionEnterRate => 'Enter the rate';

  @override
  String accountsListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '$count account',
    );
    return '$_temp0';
  }

  @override
  String get accountsDialogDeleteMessage => 'Delete this account?';

  @override
  String get accountsFormTypeTitle => 'Account type';

  @override
  String get accountsFormCustomisationTitle => 'Customisation';

  @override
  String get accountsFormDetailsTitle => 'Details';

  @override
  String get accountsFormBankName => 'Bank name (optional)';

  @override
  String get accountsFormBankNamePlaceholder => 'e.g. My bank';

  @override
  String get accountsFormCustomLogo => 'Custom logo (optional)';

  @override
  String get accountsFormLogoCamera => 'Camera';

  @override
  String get accountsFormLogoGallery => 'Gallery';

  @override
  String get accountsFormRateProposalTitle => 'Missing exchange rate';

  @override
  String accountsFormRateProposalMessage(String from, String to) {
    return 'No $from → $to rate is defined.';
  }

  @override
  String get accountsFormRateProposalHint => 'Would you like to enter it now?';

  @override
  String get exchangeRatesDialogAddRateTitle => 'Add a rate';

  @override
  String recurringSummaryMonthlyExpenses(String amount) {
    return '~$amount /month';
  }

  @override
  String get commonNavDebts => 'Debts';

  @override
  String get commonNavSubscriptions => 'Subscriptions';

  @override
  String get debtsSummaryNet => 'Net balance';

  @override
  String debtsSummaryOutstandingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outstanding',
      one: '$count outstanding',
    );
    return '$_temp0';
  }

  @override
  String debtsSummaryLentTotal(String amount) {
    return '$amount lent';
  }

  @override
  String debtsSummaryBorrowedTotal(String amount) {
    return '$amount borrowed';
  }

  @override
  String get debtsListOverdue => 'Overdue';

  @override
  String get debtsListThisWeek => 'This week';

  @override
  String get debtsListThisMonth => 'This month';

  @override
  String get debtsListLater => 'Later';

  @override
  String get debtsListNoDueDate => 'No due date';

  @override
  String get debtsListRepaid => 'Repaid';

  @override
  String get debtsDialogCreateTitle => 'New debt';

  @override
  String get debtsDialogEditTitle => 'Edit debt';

  @override
  String get debtsDialogRepayTitle => 'Repayment';

  @override
  String get debtsValueNotRepaid => 'Not repaid';

  @override
  String get debtsFormCurrencyPlaceholder => 'Default currency';

  @override
  String debtsFormReminderSummary(String date, String time) {
    return 'Reminder: $date at $time';
  }

  @override
  String debtsDetailReminderAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get debtsActionClearReminder => 'Clear the reminder';

  @override
  String get subscriptionsSummaryMonthlyTotal => 'Monthly total';

  @override
  String subscriptionsSummaryActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '$count subscription',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsListActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '$count active',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsListActive => 'Active';

  @override
  String get subscriptionsListInactive => 'Inactive';

  @override
  String get subscriptionsValuePerWeek => '/week';

  @override
  String get subscriptionsValueWeekly => 'Weekly';

  @override
  String get subscriptionsValueMonthly => 'Monthly';

  @override
  String get subscriptionsValueYearly => 'Yearly';

  @override
  String get subscriptionsDialogCreateTitle => 'New subscription';

  @override
  String get subscriptionsDialogEditTitle => 'Edit subscription';

  @override
  String get subscriptionsFormCategory => 'Category';

  @override
  String get subscriptionsFormCurrency => 'Currency';

  @override
  String get subscriptionsFormCurrencyPlaceholder => 'Default currency';

  @override
  String get subscriptionsDetailAmount => 'Amount';

  @override
  String get subscriptionsDetailStartDate => 'Start date';

  @override
  String get exchangeRatesValueEur => 'Euro';

  @override
  String get exchangeRatesValueXof => 'CFA Franc (BCEAO)';

  @override
  String get exchangeRatesValueUsd => 'US Dollar';

  @override
  String get exchangeRatesValueGbp => 'Pound Sterling';

  @override
  String get exchangeRatesValueChf => 'Swiss Franc';

  @override
  String get exchangeRatesValueCad => 'Canadian Dollar';

  @override
  String get exchangeRatesValueMad => 'Moroccan Dirham';

  @override
  String get budgetsPageTitle => 'Budgets';

  @override
  String get budgetsPageUnbudgetedTitle => 'Unbudgeted';

  @override
  String get budgetsDialogCreateTitle => 'New budget';

  @override
  String get budgetsActionDeactivate => 'Deactivate';

  @override
  String get budgetsEmptyNoTransactions => 'No transactions this month';

  @override
  String get budgetsListInactive => 'Inactive';

  @override
  String budgetsDetailOverBudget(String amount) {
    return 'over $amount';
  }

  @override
  String budgetsDetailRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String get budgetsSummarySpent => 'Spent';

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
      other: '$count over budget',
      one: '$count over budget',
    );
    return '$_temp0';
  }

  @override
  String budgetsSummaryExceededCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets exceeded',
      one: '$count budget exceeded',
    );
    return '$_temp0';
  }

  @override
  String budgetsSummaryUnbudgeted(String amount) {
    return '$amount unbudgeted';
  }

  @override
  String budgetsSummaryMonthlyInCurrency(String currency) {
    return 'Monthly · in $currency';
  }

  @override
  String budgetsSummaryTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get budgetsValueWeekly => 'Weekly';

  @override
  String get budgetsValueMonthly => 'Monthly';

  @override
  String get budgetsValueYearly => 'Yearly';

  @override
  String get dashboardPageRecentTransactionsTitle => 'Recent transactions';

  @override
  String dashboardSummaryGreetingMorning(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Good morning $name',
      'other': 'Good morning',
    });
    return '$_temp0';
  }

  @override
  String dashboardSummaryGreetingAfternoon(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Good afternoon $name',
      'other': 'Good afternoon',
    });
    return '$_temp0';
  }

  @override
  String dashboardSummaryGreetingEvening(String hasName, String name) {
    String _temp0 = intl.Intl.selectLogic(hasName, {
      'yes': 'Good evening $name',
      'other': 'Good evening',
    });
    return '$_temp0';
  }

  @override
  String get dashboardSummaryMonthPositive => 'Positive month';

  @override
  String get dashboardSummaryMonthNegative => 'Negative month';

  @override
  String get dashboardSummaryMonthQuiet => 'Quiet month';

  @override
  String get dashboardEmptyTitle => 'Welcome!';

  @override
  String get dashboardEmptyMessage =>
      'Start by creating an account\nto track your finances.';

  @override
  String recurringSummaryOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses overdue',
      one: '$count expense overdue',
    );
    return '$_temp0';
  }

  @override
  String get recurringActionValidate => 'Validate';

  @override
  String get recurringActionSkip => 'Skip';

  @override
  String get accountsSummaryNetWorth => 'Total net worth';

  @override
  String get exchangeRatesFeedbackConversionIncompleteHint =>
      'Some amounts could not be converted';

  @override
  String get transactionsEmptyTitle => 'No transactions';

  @override
  String get commonActionViewAll => 'View all';

  @override
  String get commonNavHome => 'Home';

  @override
  String get commonNavTransactions => 'Transactions';

  @override
  String get commonNavBudgets => 'Budgets';

  @override
  String get commonActionDisable => 'Disable';

  @override
  String get settingsPageManagementTitle => 'Management';

  @override
  String get settingsPageAdministrationTitle => 'Administration';

  @override
  String get settingsPageAppearanceTitle => 'Appearance';

  @override
  String get settingsPageNavigationTitle => 'Navigation';

  @override
  String get settingsPageNotificationsTitle => 'Notifications';

  @override
  String get settingsPageTimezoneTitle => 'Time zone';

  @override
  String get settingsListAccounts => 'Accounts & Currencies';

  @override
  String get settingsListAccountsHint => 'Manage accounts and currencies';

  @override
  String get settingsListCategories => 'Categories';

  @override
  String get settingsListCategoriesHint => 'Manage categories';

  @override
  String get settingsListTextScalePreview =>
      'Here is a preview of the chosen text size.';

  @override
  String settingsListVersion(String version) {
    return 'K-Budget v$version';
  }

  @override
  String get settingsFormTheme => 'Theme';

  @override
  String get settingsFormTextScale => 'Text size';

  @override
  String get settingsFormTimezoneHint => 'Used for the day-before reminders';

  @override
  String get settingsValueThemeLight => 'Light';

  @override
  String get settingsValueThemeDark => 'Dark';

  @override
  String get settingsValueThemeAuto => 'Auto';

  @override
  String get settingsValueTextScaleSmall => 'Small';

  @override
  String get settingsValueTextScaleMedium => 'Normal';

  @override
  String get settingsValueTextScaleLarge => 'Large';

  @override
  String get settingsValueChecking => 'Checking…';

  @override
  String get settingsValueOnline => 'Online';

  @override
  String get settingsValueOffline => 'Offline';

  @override
  String settingsDialogDisableFeatureTitle(String feature) {
    return 'Disable $feature?';
  }

  @override
  String get settingsDialogDisableFeatureMessage =>
      'Your data will be hidden, not deleted.';

  @override
  String get settingsFeedbackLoadError => 'Unable to load preferences';

  @override
  String get settingsFeedbackSaveError => 'Unable to save preferences';

  @override
  String get settingsPageDataTitle => 'Data';

  @override
  String get settingsFormDataSource => 'Data source';

  @override
  String get settingsValueDataSourceLocal => 'Local';

  @override
  String get settingsValueDataSourceServer => 'Server';

  @override
  String get settingsFormServerUrl => 'Server URL';

  @override
  String get settingsFormServerUrlRequired => 'The server URL is required';

  @override
  String get settingsFormServerUrlHttpsRequired =>
      'The URL must start with https://';

  @override
  String get settingsFeedbackServerUrlSaved => 'URL saved';

  @override
  String get settingsFeedbackServerUnreachable => 'Server unreachable';

  @override
  String get settingsFeedbackServerTimeout => 'Connection timed out';

  @override
  String get settingsFeedbackServerAccessDenied =>
      'Access denied by the server';

  @override
  String get settingsFeedbackServerNotFound =>
      'Endpoint not found — check the URL';

  @override
  String get settingsDialogChangeDataSourceTitle => 'Change data source?';

  @override
  String get settingsDialogChangeDataSourceMessage =>
      'Data sources are independent. The data of the current source will not be visible after the change.\n\nThe app will restart to apply the new source.';

  @override
  String get notificationsValueSubscriptionDue => 'Subscription due';

  @override
  String get notificationsValueDebtDue => 'Debt due';

  @override
  String get notificationsValueDebtReminder => 'Debt reminder';

  @override
  String get notificationsValueRecurringTransactionDue =>
      'Recurring transaction due';

  @override
  String get notificationsValueBudgetThreshold => 'Budget threshold reached';

  @override
  String get notificationsValueBudgetExceeded => 'Budget exceeded';

  @override
  String get usersListProfile => 'Profile';

  @override
  String get usersListProfileHint => 'Profile, security, sign out';

  @override
  String get usersListManageHint => 'Invitations and access management';

  @override
  String get usersListChangePassword => 'Change password';

  @override
  String get usersListExportJson => 'Export my data (JSON)';

  @override
  String get usersListExportCsv => 'Export my transactions (CSV)';

  @override
  String get usersPageAdminTitle => 'Users';

  @override
  String get usersPageProfileTitle => 'Profile';

  @override
  String get usersPageIdentityTitle => 'Identity';

  @override
  String get usersPageSecurityTitle => 'Security';

  @override
  String get usersPageDataTitle => 'Data';

  @override
  String get usersPageDangerZoneTitle => 'Danger zone';

  @override
  String get usersFormEmailManagedHint => 'Managed by the admin';

  @override
  String get usersFormCurrentPassword => 'Current password';

  @override
  String get usersFormNewPassword => 'New password';

  @override
  String get usersFormConfirmNewPassword => 'Confirm the new password';

  @override
  String get usersFormPasswordMismatch => 'Passwords do not match.';

  @override
  String get usersFormDeleteAccountConfirm =>
      'I understand that this action is permanent';

  @override
  String get usersValueNameNotSet => 'Not set';

  @override
  String get usersActionDeleteAccount => 'Delete my account';

  @override
  String get usersActionChangePhoto => 'Change photo';

  @override
  String get usersActionDeletePhoto => 'Delete photo';

  @override
  String get usersActionEditPhoto => 'Edit photo';

  @override
  String get usersDialogDeleteAccountMessage =>
      'Your account will be deactivated. You will no longer be able to sign in with these credentials. Your data is kept in the database for traceability.';

  @override
  String get usersFeedbackProfileLoadError => 'Unable to load the profile';

  @override
  String get usersFeedbackNameSaveError =>
      'Unable to save the name. Please try again.';

  @override
  String get usersFeedbackExportJsonError =>
      'Error during the JSON export. Please try again.';

  @override
  String get usersFeedbackExportCsvError =>
      'Error during the CSV export. Please try again.';

  @override
  String get usersFeedbackDownloading => 'Downloading…';

  @override
  String get usersFeedbackAvatarUploadError =>
      'Unable to upload the photo. Please try again.';

  @override
  String get usersFeedbackPasswordChanged => 'Password changed';

  @override
  String get usersFeedbackPasswordChangeError =>
      'Unable to change the password';

  @override
  String get usersFeedbackDeleteAccountError =>
      'Error during deletion. Please try again.';

  @override
  String get errorsApiFileTooLarge =>
      'File too large. The maximum size is 2 MB.';

  @override
  String get errorsApiInvalidImageFormat =>
      'Only JPG and PNG formats are accepted.';

  @override
  String get commonActionEnable => 'Enable';

  @override
  String get authFormEmailAddress => 'Email address';

  @override
  String get usersPageInvitationsTab => 'Invitations';

  @override
  String get usersActionInvite => 'Invite a user';

  @override
  String get usersActionCreateInvite => 'Create and copy the link';

  @override
  String get usersActionCopyLink => 'Copy the link';

  @override
  String get usersActionRevoke => 'Revoke';

  @override
  String get usersEmptyInvitations => 'No invitations yet';

  @override
  String get usersEmptyUsers => 'No users found';

  @override
  String get usersFormEmailPlaceholder => 'new@example.com';

  @override
  String usersListInvitedBy(String email) {
    return 'By $email';
  }

  @override
  String get usersValueAdmin => 'Admin';

  @override
  String get usersValueInvitationActive => 'Active';

  @override
  String get usersValueInvitationExpired => 'Expired';

  @override
  String get usersValueInvitationUsed => 'Used';

  @override
  String get usersValueInvitationRevoked => 'Revoked';

  @override
  String get usersFeedbackLinkCopied => 'Link copied to the clipboard.';

  @override
  String get usersFeedbackInviteCreated =>
      'Invitation created and link copied to the clipboard.';

  @override
  String get usersFeedbackInviteCreateError =>
      'Unable to create the invitation.';

  @override
  String get usersFeedbackInviteRevokeError =>
      'Unable to revoke the invitation.';

  @override
  String get usersFeedbackLoadUsersError => 'Unable to load users.';

  @override
  String get usersFeedbackLoadInvitationsError => 'Unable to load invitations.';

  @override
  String get usersFeedbackUserDisableError => 'Unable to disable the user.';

  @override
  String get usersFeedbackUserEnableError => 'Unable to re-enable the user.';

  @override
  String get exchangeRatesPageTitle => 'Currencies & Rates';

  @override
  String get exchangeRatesPageCurrenciesTitle => 'My currencies';

  @override
  String get exchangeRatesPageRatesTitle => 'Conversion rates';

  @override
  String get exchangeRatesPageCalculatorTitle => 'Calculator';

  @override
  String get exchangeRatesDialogEditRateTitle => 'Edit the rate';

  @override
  String get exchangeRatesDialogAddCurrencyTitle => 'Add a currency';

  @override
  String exchangeRatesDialogDeleteRateMessage(
    String baseCurrency,
    String targetCurrency,
  ) {
    return 'Delete the rate $baseCurrency → $targetCurrency?';
  }

  @override
  String exchangeRatesDialogRemoveTitle(String currency) {
    return 'Remove $currency?';
  }

  @override
  String exchangeRatesDialogRemoveMessage(String currency) {
    return 'The currency $currency is used by existing accounts. Remove anyway?';
  }

  @override
  String exchangeRatesDialogRemoveUnusedMessage(String currency) {
    return 'Remove $currency from your currencies?';
  }

  @override
  String get exchangeRatesActionRemove => 'Remove';

  @override
  String get exchangeRatesActionRemoveCurrencyAria => 'Remove this currency';

  @override
  String get exchangeRatesValuePrimary => 'Primary';

  @override
  String exchangeRatesValueCalculatedRate(String from, String rate, String to) {
    return 'Rate: 1 $from = $rate $to';
  }

  @override
  String get exchangeRatesEmptyTitle => 'No rates configured';

  @override
  String get exchangeRatesEmptyCalculator =>
      'Enter two amounts to calculate the rate';

  @override
  String get exchangeRatesFeedbackLoadError => 'Unable to load exchange rates';

  @override
  String get exchangeRatesFeedbackSaveError => 'Error saving the rate.';

  @override
  String get exchangeRatesFormBaseCurrency => 'Base currency';

  @override
  String get exchangeRatesFormTargetCurrency => 'Target currency';

  @override
  String get exchangeRatesFormCurrency => 'Currency';

  @override
  String get exchangeRatesFormCalculatorFrom => 'I have';

  @override
  String exchangeRatesFormRateWithPair(String base, String target) {
    return 'Rate (1 $base = X $target)';
  }

  @override
  String get exchangeRatesFormRateInvalid => 'Please enter a valid rate (> 0).';

  @override
  String get exchangeRatesFormRatePlaceholder => 'e.g. 655.957';
}
