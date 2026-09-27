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
  String get errorNetwork => 'Network connection error';

  @override
  String get errorsApiBadRequest => 'The request could not be processed.';

  @override
  String get errorsApiValidationError =>
      'Please check the information you entered.';

  @override
  String get errorsApiMalformedRequest => 'Invalid request.';

  @override
  String get errorCodePasswordIncorrect => 'Incorrect password';

  @override
  String get errorCodeCurrentPasswordIncorrect => 'Current password incorrect';

  @override
  String get errorCodePasswordUnchanged =>
      'The new password must be different from the current one';

  @override
  String get errorsApiConfirmationRequired => 'Explicit confirmation required.';

  @override
  String get errorCodeUnauthenticated => 'Authentication required';

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
  String get errorCodePasswordResetRequired => 'Credentials reset required';

  @override
  String get errorsApiPasswordResetNotRequired =>
      'Credentials reset is not required for this account.';

  @override
  String get errorsApiFeatureDisabled => 'Feature disabled';

  @override
  String get errorCodeLastAdminDeletionForbidden =>
      'You are the last administrator. Please appoint another administrator before deleting your account.';

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
  String get transactionsEmptyMonth => 'No transactions this month';

  @override
  String get transactionsNoCategory => 'No category';

  @override
  String get transactionsFormDescriptionPlaceholder => 'Description';

  @override
  String get transactionsFormAccount => 'Account';

  @override
  String get transactionFormDeleteConfirmTitle => 'Delete transaction';

  @override
  String get transactionFormDeleteConfirmMessage =>
      'Are you sure you want to delete this transaction? This action is irreversible.';

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
  String get transferFormSaveButton => 'Confirm';

  @override
  String get transactionsFormTransferAccountsMismatch =>
      'The source and destination accounts must be different';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationAmountPositive => 'The amount must be positive';

  @override
  String validationMaxLength(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get accountsTitle => 'Accounts';

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
  String get accountFormActiveDefaultHint =>
      'The default account cannot be deactivated';

  @override
  String get accountsFormCurrentBalance => 'Current balance';

  @override
  String get accountsFormNewBalance => 'New balance';

  @override
  String get accountFormPreviewPlaceholder => 'Account preview';

  @override
  String get accountsValueDefault => 'Default';

  @override
  String get accountDeleteConfirmTitle => 'Delete account';

  @override
  String get accountDeleteConfirmMessage =>
      'Are you sure you want to delete this account? This action is irreversible.';

  @override
  String get accountErrorLoad => 'Unable to load accounts';

  @override
  String get accountErrorCreate => 'Error creating account';

  @override
  String get accountErrorUpdate => 'Error updating account';

  @override
  String get accountErrorDelete => 'Error deleting account';

  @override
  String get categoriesPageTitle => 'Categories';

  @override
  String get categoriesEmptyNoCategories => 'No categories';

  @override
  String get categoriesDialogCreateTitle => 'New category';

  @override
  String get categoriesDialogEditTitle => 'Edit category';

  @override
  String get categoryFormNameField => 'Category name';

  @override
  String get categoryFormIconField => 'Icon';

  @override
  String get categoryNameRequired => 'Name is required';

  @override
  String get categoryNameMaxLength => '30 characters maximum';

  @override
  String get categoryNameDuplicate => 'This category name already exists';

  @override
  String get categoryEmojiRequired => 'Icon is required';

  @override
  String get categoryDeleteConfirmTitle => 'Delete category';

  @override
  String get categoryDeleteConfirmMessage =>
      'Are you sure you want to delete this category? Related items will be unlinked.';

  @override
  String get categoryErrorLoad => 'Unable to load categories';

  @override
  String get categoryErrorCreate => 'Error creating category';

  @override
  String get categoryErrorUpdate => 'Error updating category';

  @override
  String get categoryErrorDelete => 'Error deleting category';

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
  String recurringNextOccurrence(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringMonthlySummaryTitle => 'MONTHLY SUMMARY';

  @override
  String recurringChargesCount(int count) {
    return '$count EXPENSES';
  }

  @override
  String get recurringEmpty => 'No active recurring transactions';

  @override
  String get recurringFeedbackValidated => 'Transaction created';

  @override
  String get recurringSkipSuccess => 'Occurrence skipped';

  @override
  String get recurringFeedbackDeactivated =>
      'Recurring transaction deactivated';

  @override
  String get frequencyHebdomadaire => '/week';
}
