import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/adaptive_scaffold.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/app_toggle.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/common_widgets/fab_menu.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/features/auth/presentation/login_screen.dart';
import 'package:k_budget/src/features/admin/presentation/users_screen.dart';
import 'package:k_budget/src/features/auth/presentation/accept_invite_screen.dart';
import 'package:k_budget/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:k_budget/src/features/debts/presentation/debt_list_screen.dart';
import 'package:k_budget/src/features/debts/presentation/debt_detail_screen.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:k_budget/src/features/onboarding/presentation/server_setup_screen.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/features/settings/presentation/data_settings_screen.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/currency_settings_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_list_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_form_screen.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_list_screen.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_form_screen.dart';
import 'package:k_budget/src/features/user_profile/presentation/screens/profile_settings_screen.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_list_screen.dart';
import 'package:k_budget/src/features/budgets/presentation/budget_detail_screen.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_form.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/features/recurring/presentation/recurring_list_screen.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_list_screen.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/debt_form.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/features/subscriptions/presentation/widgets/subscription_form.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_notifier.dart';
import 'package:k_budget/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transfer_form.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/features/compatibility/presentation/incompatible_screen.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/services/local_notification_service.dart';
import 'package:k_budget/src/services/stomp_service.dart';
import 'package:k_budget/src/utils/env_config.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingNotifier = ref.read(onboardingNotifierProvider.notifier);
  final authNotifier = ref.read(authNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.dashboard,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final isCompleted = await onboardingNotifier.isOnboardingCompleted();
      final matchedLocation = state.matchedLocation;
      final isOnboarding = matchedLocation.startsWith(RouteNames.onboarding);
      final isLoginRoute = matchedLocation == RouteNames.login;
      final isLockRoute = matchedLocation == RouteNames.lock;
      final isAuthRoute = isLoginRoute;
      final isInviteRoute = matchedLocation.startsWith('/invite') ||
          matchedLocation.startsWith('/accept-invite');

      // Not onboarded yet → go to onboarding
      if (!isCompleted && !isOnboarding) {
        return RouteNames.onboarding;
      }
      // Onboarded but trying to access onboarding → go to dashboard
      if (isCompleted && isOnboarding) {
        return RouteNames.dashboard;
      }

      // Only apply auth/lock checks after onboarding
      if (isCompleted) {
        final config = await onboardingNotifier.getConfig();

        // Server mode: check authentication
        if (config.dataMode == DataMode.server) {
          // Compatibilite du serveur (KKS-314), verifiee une fois par session.
          // Un serveur injoignable ne redirige pas : hors ligne n'est pas une
          // incompatibilite, le cache prend le relais (constitution,
          // principe IV).
          final compatibility =
              await ref
                  .read(compatibilityNotifierProvider.notifier)
                  .ensureChecked();
          final isIncompatible = compatibility is CompatibilityServerTooOld ||
              compatibility is CompatibilityClientTooOld;
          final isIncompatibleRoute =
              matchedLocation == RouteNames.incompatible;

          if (isIncompatible && !isIncompatibleRoute) {
            return RouteNames.incompatible;
          }
          if (!isIncompatible && isIncompatibleRoute) {
            return RouteNames.dashboard;
          }

          final authState = ref.read(authNotifierProvider);

          // Premier lancement : valider les tokens stockés
          if (authState is AuthInitial) {
            await ref.read(authNotifierProvider.notifier).checkAuth();
          }

          final currentAuthState = ref.read(authNotifierProvider);
          final isAuthenticated = currentAuthState is AuthAuthenticated;

          if (!isAuthenticated && !isAuthRoute && !isInviteRoute) {
            return RouteNames.login;
          }
          if (isAuthenticated && isAuthRoute) {
            return RouteNames.dashboard;
          }
        }

        // Lock screen check (both modes)
        if (config.lockEnabled && isLockRoute) {
          return null; // Stay on lock screen
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        name: RouteNames.onboardingName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: RouteNames.serverSetup,
            name: RouteNames.serverSetupName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const ServerSetupScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.loginName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.incompatible,
        name: RouteNames.incompatibleName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IncompatibleScreen(),
      ),
      GoRoute(
        path: '/accept-invite/:token',
        name: RouteNames.acceptInviteName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AcceptInviteScreen(
          token: state.pathParameters['token']!,
        ),
      ),
      GoRoute(
        path: '/invite/:token',
        name: 'invite',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AcceptInviteScreen(
          token: state.pathParameters['token']!,
        ),
      ),
      GoRoute(
        path: RouteNames.lock,
        name: RouteNames.lockName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            name: RouteNames.dashboardName,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.transactions,
            name: RouteNames.transactionsName,
            builder: (context, state) => const TransactionListScreen(),
            routes: [
              GoRoute(
                path: 'recurring',
                name: RouteNames.recurringName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const RecurringListScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.subscriptions,
            name: RouteNames.subscriptionsName,
            builder: (context, state) => const SubscriptionListScreen(),
            routes: [
              GoRoute(
                path: RouteNames.subscriptionDetail,
                name: RouteNames.subscriptionDetailName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final subscription = state.extra as Subscription?;
                  return SubscriptionDetailScreen(
                    subscriptionId: state.pathParameters['id']!,
                    initialSubscription: subscription,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.debts,
            name: RouteNames.debtsName,
            builder: (context, state) => const DebtListScreen(),
            routes: [
              GoRoute(
                path: RouteNames.debtDetail,
                name: RouteNames.debtDetailName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final debt = state.extra as Debt?;
                  return DebtDetailScreen(
                    debtId: state.pathParameters['id']!,
                    initialDebt: debt,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.budgets,
            name: RouteNames.budgetsName,
            builder: (context, state) => const BudgetListScreen(),
            routes: [
              GoRoute(
                path: 'details',
                name: RouteNames.budgetDetailsName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final categoryId = state.uri.queryParameters['categoryId'] ?? '';
                  final month = state.uri.queryParameters['month'];
                  return BudgetDetailScreen(categoryId: categoryId, month: month);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.settings,
        name: RouteNames.settingsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsHubScreen(),
        routes: [
          GoRoute(
            path: RouteNames.settingsProfile,
            name: RouteNames.settingsProfileName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                const ProfileSettingsScreen(),
          ),
          GoRoute(
            path: RouteNames.settingsAccounts,
            name: RouteNames.settingsAccountsName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const AccountListScreen(),
            routes: [
              GoRoute(
                path: RouteNames.settingsAccountsNew,
                name: RouteNames.settingsAccountsNewName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AccountFormScreen(),
              ),
              GoRoute(
                path: RouteNames.settingsAccountsEdit,
                name: RouteNames.settingsAccountsEditName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final account = state.extra as Account?;
                  return AccountFormScreen(account: account);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.settingsCategories,
            name: RouteNames.settingsCategoriesName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CategoryListScreen(),
            routes: [
              GoRoute(
                path: RouteNames.settingsCategoriesNew,
                name: RouteNames.settingsCategoriesNewName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: RouteNames.settingsCategoriesEdit,
                name: RouteNames.settingsCategoriesEditName,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final category = state.extra as Category?;
                  return CategoryFormScreen(category: category);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.settingsData,
            name: RouteNames.settingsDataName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const DataSettingsScreen(),
          ),
          GoRoute(
            path: RouteNames.settingsCurrencies,
            name: RouteNames.settingsCurrenciesName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CurrencySettingsScreen(),
          ),
          GoRoute(
            path: 'users',
            name: RouteNames.adminUsersName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const UsersScreen(),
          ),
        ],
      ),
    ],
  );
});

class _ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  ConsumerState<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<_ShellScaffold> {
  bool _isModalShowing = false;

  @override
  void initState() {
    super.initState();
    _connectStomp();
  }

  @override
  void dispose() {
    try {
      ref.read(stompServiceProvider).disconnect();
    } catch (_) {
      // Ignore: provider may not be available during test teardown
    }
    super.dispose();
  }

  Future<void> _connectStomp() async {
    try {
      final configRepo = ref.read(appConfigRepositoryProvider);
      final dataMode = await configRepo.getDataMode();
      if (dataMode != DataMode.server) return;

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null) return;

      final serverUrl = await configRepo.getServerUrl();
      final baseUrl = (serverUrl ?? EnvConfig.apiBaseUrl)
          .replaceFirst('https', 'wss')
          .replaceFirst('http', 'ws')
          .replaceFirst('/api', '/api/ws');

      final stompService = ref.read(stompServiceProvider);
      final localNotificationService = ref.read(localNotificationServiceProvider);

      await localNotificationService.initialize();

      stompService.connect(
        token: token,
        baseUrl: baseUrl,
        localNotificationService: localNotificationService,
        onReconnect: () {
          ref.read(notificationNotifierProvider.notifier).loadItems();
        },
      );

    } catch (_) {
      // Ignore: plugin not available in test or local mode
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureState = ref.watch(featureConfigNotifierProvider);
    final enabledFeatures = featureState.enabledFeatures;
    final navOrder = featureState.navOrder;

    // Garder les listeners STOMP vivants tant que le Shell est monté
    ref.watch(notificationStompListenerProvider);
    ref.watch(exchangeRateStompListenerProvider);

    // Build dynamic paths and destinations
    final paths = <String>[
      RouteNames.dashboard,
      RouteNames.transactions,
    ];
    final destinations = <NavDestination>[
      const NavDestination(
        icon: PhosphorIconsRegular.house,
        selectedIcon: PhosphorIconsFill.house,
        label: 'Accueil',
      ),
      const NavDestination(
        icon: PhosphorIconsRegular.receipt,
        selectedIcon: PhosphorIconsFill.receipt,
        label: 'Transactions',
      ),
    ];

    // Add enabled features in navOrder order
    final orderedEnabled = navOrder.where(enabledFeatures.contains);
    for (final feature in orderedEnabled) {
      final (path, destination) = switch (feature) {
        Feature.subscriptions => (
          RouteNames.subscriptions,
          const NavDestination(
            icon: PhosphorIconsRegular.arrowsClockwise,
            selectedIcon: PhosphorIconsFill.arrowsClockwise,
            label: 'Abonnements',
          ),
        ),
        Feature.debts => (
          RouteNames.debts,
          const NavDestination(
            icon: PhosphorIconsRegular.handshake,
            selectedIcon: PhosphorIconsFill.handshake,
            label: 'Dettes',
          ),
        ),
        Feature.budgets => (
          RouteNames.budgets,
          const NavDestination(
            icon: PhosphorIconsRegular.chartPie,
            selectedIcon: PhosphorIconsFill.chartPie,
            label: 'Budgets',
          ),
        ),
      };
      paths.add(path);
      destinations.add(destination);
    }

    final location = GoRouterState.of(context).matchedLocation;
    var currentIndex = paths.indexOf(location).clamp(0, paths.length - 1);

    // If current route is no longer in paths, redirect to dashboard
    if (!paths.contains(location)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.dashboard);
      });
      currentIndex = 0;
    }

    ref.listen<ModalState>(modalNotifierProvider, (previous, next) {
      if (next is ModalOpen && !_isModalShowing) {
        _showModal(context, next);
      }
    });

    return AdaptiveScaffold(
      currentIndex: currentIndex,
      destinations: destinations,
      onDestinationSelected: (index) {
        context.go(paths[index]);
      },
      floatingActionButton: const FabMenu(),
      body: widget.child,
    );
  }

  Widget _buildModalChild(ModalOpen state) {
    if (state.type == ModalType.transaction) {
      return _TransactionFormConsumer(
        transaction: state.entity as Transaction?,
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    } else if (state.type == ModalType.subscription) {
      return _SubscriptionFormConsumer(
        subscription: state.entity as Subscription?,
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    } else if (state.type == ModalType.debt) {
      return _DebtFormConsumer(
        debt: state.entity as Debt?,
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    } else if (state.type == ModalType.transfer) {
      return _TransferFormConsumer(
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    } else if (state.type == ModalType.budget) {
      return _BudgetFormConsumer(
        budget: state.entity as Budget?,
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showFormBottomSheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: child,
      ),
    ).then((_) {
      if (_isModalShowing) {
        _isModalShowing = false;
        ref.read(modalNotifierProvider.notifier).close();
      }
    });
  }

  void _showModal(BuildContext context, ModalOpen state) {
    _isModalShowing = true;
    final child = _buildModalChild(state);

    if (state.type == ModalType.transaction ||
        state.type == ModalType.subscription ||
        state.type == ModalType.debt) {
      _showFormBottomSheet(context, child);
    } else {
      // budget, transfer — AppModal inchangé
      Widget? headerActions;
      if (state.type.hasToggle) {
        final values = state.type.toggleValues!;
        final selectedIndex = values.indexOf(state.subType);
        headerActions = _ModalToggle(
          type: state.type,
          initialIndex: selectedIndex.clamp(0, 1),
        );
      }
      AppModal.show(
        context,
        title: state.type.title(state.mode),
        headerActions: headerActions,
        inlineHeaderActions: state.type.hasToggle,
        onClose: () {
          _isModalShowing = false;
          ref.read(modalNotifierProvider.notifier).close();
        },
        child: child,
      ).then((_) {
        if (_isModalShowing) {
          _isModalShowing = false;
          ref.read(modalNotifierProvider.notifier).close();
        }
      });
    }
  }
}

class _TransactionFormConsumer extends ConsumerWidget {
  final Transaction? transaction;
  final VoidCallback onDone;

  const _TransactionFormConsumer({
    this.transaction,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    final type = (modalState.subType as TransactionType?) ??
        TransactionType.depense;

    return TransactionForm(
      transaction: transaction,
      type: type,
      onSaved: (tx) async {
        if (transaction == null) {
          await ref.read(transactionNotifierProvider.notifier).create(tx);
        } else {
          await ref.read(transactionNotifierProvider.notifier).update(tx);
        }
        unawaited(ref.read(transactionListNotifierProvider.notifier).refresh());
        onDone();
      },
      onDeleted: transaction != null
          ? (id) async {
              await ref.read(transactionNotifierProvider.notifier).delete(id);
              unawaited(ref.read(transactionListNotifierProvider.notifier).refresh());
              onDone();
            }
          : null,
      onCancelled: onDone,
    );
  }
}

class _SubscriptionFormConsumer extends ConsumerWidget {
  final Subscription? subscription;
  final VoidCallback onDone;

  const _SubscriptionFormConsumer({
    this.subscription,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    final frequence = (modalState.subType as Frequency?) ?? Frequency.mensuel;

    return SubscriptionForm(
      subscription: subscription,
      frequence: frequence,
      onSaved: (sub) async {
        if (subscription == null) {
          await ref.read(subscriptionNotifierProvider.notifier).create(sub);
        } else {
          await ref.read(subscriptionNotifierProvider.notifier).update(sub);
        }
        onDone();
      },
      onDeleted: subscription != null
          ? (id) async {
              await ref.read(subscriptionNotifierProvider.notifier).delete(id);
              onDone();
            }
          : null,
      onCancelled: onDone,
    );
  }
}

class _DebtFormConsumer extends ConsumerWidget {
  final Debt? debt;
  final VoidCallback onDone;

  const _DebtFormConsumer({
    this.debt,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    final debtType = (modalState.subType as DebtType?) ?? DebtType.emprunt;

    return DebtForm(
      debt: debt,
      debtType: debtType,
      onSaved: (d) async {
        if (debt == null) {
          await ref.read(debtNotifierProvider.notifier).create(d);
        } else {
          await ref.read(debtNotifierProvider.notifier).update(d);
        }
        onDone();
      },
      onDeleted: debt != null
          ? (id) async {
              await ref.read(debtNotifierProvider.notifier).delete(id);
              onDone();
            }
          : null,
      onCancelled: onDone,
    );
  }
}

class _TransferFormConsumer extends ConsumerWidget {
  final VoidCallback onDone;

  const _TransferFormConsumer({required this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountNotifierProvider);
    final activeAccounts = accountState.items.where((a) => a.actif).toList();

    return TransferForm(
      accounts: activeAccounts,
      onSaved: (request) async {
        final dataSource =
            await ref.read(accountRemoteDataSourceProvider.future);
        await dataSource.transfer(request);
        if (!context.mounted) return;
        unawaited(
            ref.read(transactionListNotifierProvider.notifier).refresh());
        unawaited(ref.read(accountNotifierProvider.notifier).refresh());
        onDone();
      },
      onCancelled: onDone,
    );
  }
}

class _BudgetFormConsumer extends ConsumerWidget {
  final Budget? budget;
  final VoidCallback onDone;

  const _BudgetFormConsumer({
    this.budget,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    return BudgetForm(
      budget: budget,
      onSaved: (b) async {
        if (budget == null) {
          await ref.read(budgetNotifierProvider.notifier).create(b);
        } else {
          await ref.read(budgetNotifierProvider.notifier).update(b);
        }
        onDone();
      },
      onDeleted: budget != null
          ? (id) async {
              await ref.read(budgetNotifierProvider.notifier).delete(id);
              onDone();
            }
          : null,
      onCancelled: onDone,
    );
  }
}

class _ModalToggle extends ConsumerWidget {
  final ModalType type;
  final int initialIndex;

  const _ModalToggle({required this.type, required this.initialIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    final labels = type.toggleLabels!;
    final values = type.toggleValues!;
    final selectedIndex = values.indexOf(modalState.subType).clamp(0, 1);

    return AppToggle(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: (index) {
        ref.read(modalNotifierProvider.notifier).setSubType(values[index]);
      },
    );
  }
}
