class RouteNames {
  RouteNames._();

  // Paths
  static const String onboarding = '/onboarding';
  static const String serverSetup = 'server-setup';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String subscriptions = '/subscriptions';
  static const String debts = '/debts';
  static const String debtDetail = ':id'; // relatif
  static const String subscriptionDetail = ':id'; // relatif
  static const String settings = '/settings';
  static const String budgets = '/budgets';
  static const String budgetDetails = '/budgets/details';
  static const String login = '/login';
  static const String lock = '/lock';
  static const String acceptInvite = '/accept-invite/:token';
  static const String adminUsers = '/settings/users';

  // Settings sub-paths (relative)
  static const String settingsProfile = 'profile';
  static const String settingsAccounts = 'accounts';
  static const String settingsCategories = 'categories';
  static const String settingsData = 'data';
  static const String settingsCurrencies = 'currencies';

  // Names
  static const String onboardingName = 'onboarding';
  static const String serverSetupName = 'server-setup';
  static const String dashboardName = 'dashboard';
  static const String transactionsName = 'transactions';
  static const String subscriptionsName = 'subscriptions';
  static const String debtsName = 'debts';
  static const String settingsName = 'settings';
  static const String loginName = 'login';
  static const String lockName = 'lock';
  static const String acceptInviteName = 'acceptInvite';
  static const String adminUsersName = 'adminUsers';
  static const String settingsProfileName = 'settings-profile';
  static const String settingsAccountsName = 'settings-accounts';
  static const String settingsCategoriesName = 'settings-categories';
  static const String settingsDataName = 'settings-data';
  static const String settingsCurrenciesName = 'settings-currencies';
  static const String budgetsName = 'budgets';
  static const String budgetDetailsName = 'budget-details';
  static const String debtDetailName = 'debt-detail';
  static const String subscriptionDetailName = 'subscription-detail';
  static const String settingsAccountsNewName = 'settings-accounts-new';
  static const String settingsAccountsEditName = 'settings-accounts-edit';

  // Settings sub-paths (relative, accounts)
  static const String settingsAccountsNew = 'new';
  static const String settingsAccountsEdit = ':id';

  // Settings sub-paths (relative, categories)
  static const String settingsCategoriesNew = 'new';
  static const String settingsCategoriesEdit = ':id';

  // Names (categories)
  static const String settingsCategoriesNewName = 'settings-categories-new';
  static const String settingsCategoriesEditName = 'settings-categories-edit';

  // Recurring transactions
  static const String recurring = '/transactions/recurring';
  static const String recurringName = 'recurring';
}
