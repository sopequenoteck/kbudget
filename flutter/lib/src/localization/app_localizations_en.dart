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
  String get amount => 'Amount';

  @override
  String get currency => 'Currency';

  @override
  String get frequency => 'Frequency';

  @override
  String get budgetsFormCategory => 'Category';

  @override
  String get selectCategory => 'Choose a category';

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
  String get subscriptionFormDeleteConfirmTitle => 'Delete subscription';

  @override
  String get subscriptionFormDeleteConfirmMessage =>
      'Are you sure you want to delete this subscription? This action is irreversible.';

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions';

  @override
  String get subscriptionsValuePerMonth => '/month';

  @override
  String get subscriptionsValuePerYear => '/year';

  @override
  String subscriptionNextRenewal(String date) {
    return 'Next: $date';
  }

  @override
  String get commonValueInactive => 'Inactive';

  @override
  String get subscriptionsActionPay => 'Pay';

  @override
  String get subscriptionsFeedbackPaid => 'Payment recorded';

  @override
  String get subscriptionPaymentHistory => 'Payment history';

  @override
  String get subscriptionNoPayments => 'No payments';

  @override
  String subscriptionPayments(int count) {
    return '$count payments';
  }

  @override
  String get debtsFormPersonPlaceholder => 'Person';

  @override
  String get debtFormDeleteConfirmTitle => 'Delete debt';

  @override
  String get debtFormDeleteConfirmMessage =>
      'Are you sure you want to delete this debt? This action is irreversible.';

  @override
  String get debtFormAccountPicker => 'Bank account';

  @override
  String get debtsEmptyTitle => 'No debts';

  @override
  String get debtsValueRepaid => 'Repaid';

  @override
  String get debtDetailInitialAmount => 'Initial amount';

  @override
  String get debtDetailRemainingAmount => 'Remaining amount';

  @override
  String get debtsActionRepay => 'Repay';

  @override
  String get debtsDialogSnoozeTitle => 'Snooze the reminder';

  @override
  String get debtDetailProgress => 'Progress';

  @override
  String get debtDetailDate => 'Date';

  @override
  String get debtDetailCurrency => 'Currency';

  @override
  String get debtsFormAccount => 'Account';

  @override
  String get debtDetailAccountDeleted => 'Account deleted';

  @override
  String get debtDetailDueDate => 'Due date';

  @override
  String get debtsFormCategory => 'Category';

  @override
  String get debtDetailIncludedInBalance => 'Included in balance';

  @override
  String get debtsFormReminderAria => 'Reminder';

  @override
  String get debtsDetailPayments => 'Payments';

  @override
  String get debtDetailTotalRepaid => 'Total repaid';

  @override
  String get commonEmptyNoPayments => 'No payments recorded';

  @override
  String get debtDetailPaymentsError => 'Unable to load payments';

  @override
  String get debtsValueBorrowed => 'Borrowed';

  @override
  String get debtsValueLent => 'Lent';

  @override
  String get repayAccountLabel => 'Source account';

  @override
  String get debtsFormAccountPlaceholder => 'Select an account';

  @override
  String get repayAccountRequired => 'Account required';

  @override
  String get repayAmountLabel => 'Amount';

  @override
  String get repayAmountRequired => 'Amount required';

  @override
  String get debtsFeedbackAmountInvalid => 'Invalid amount';

  @override
  String repayAmountMax(String amount) {
    return 'Maximum: $amount';
  }

  @override
  String get repayNoAccounts =>
      'No active accounts. Create an account in settings.';

  @override
  String get repaySuccess => 'Repayment recorded';

  @override
  String get debtsFeedbackRepayError => 'Repayment failed';

  @override
  String get snoozeDateLabel => 'New date';

  @override
  String get snoozeTimeLabel => 'Time';

  @override
  String get snoozeDateFutureRequired => 'The date must be in the future';

  @override
  String get debtsFeedbackSnoozed => 'Reminder snoozed';

  @override
  String get snoozeError => 'Failed to snooze the reminder';

  @override
  String get debtsActionSnooze => 'Snooze';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

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
  String get emptyBudgetList => 'No budget';

  @override
  String get deleteBudgetTitle => 'Delete budget';

  @override
  String get deleteBudgetMessage =>
      'Are you sure you want to delete this budget? This action is irreversible.';

  @override
  String get allCategoriesHaveBudgets => 'All categories already have a budget';

  @override
  String get total => 'Total';

  @override
  String get budgetOtherCategory => 'Other';

  @override
  String get budgetActive => 'Active budget';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notificationsActionMarkAllReadHint => 'Mark all as read';

  @override
  String get notificationsActionDeleteAllHint => 'Clear history';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationClearConfirmMessage =>
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
}
