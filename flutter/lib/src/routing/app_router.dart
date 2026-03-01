import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/adaptive_scaffold.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/app_toggle.dart';
import 'package:k_budget/src/common_widgets/fab_menu.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/features/auth/presentation/login_screen.dart';
import 'package:k_budget/src/features/auth/presentation/register_screen.dart';
import 'package:k_budget/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:k_budget/src/features/debts/presentation/debt_list_screen.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:k_budget/src/features/onboarding/presentation/server_setup_screen.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/features/settings/presentation/data_settings_screen.dart';
import 'package:k_budget/src/features/settings/presentation/appearance_settings_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_list_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_form_screen.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_list_screen.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_form_screen.dart';
import 'package:k_budget/src/features/user_profile/presentation/screens/profile_settings_screen.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/feature_settings_screen.dart';
import 'package:k_budget/src/features/shop/presentation/product_list_screen.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_list_screen.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/features/shop/application/product_notifier.dart';
import 'package:k_budget/src/features/shop/presentation/widgets/product_form.dart';
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
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/routing/route_names.dart';

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
      final isRegisterRoute = matchedLocation == RouteNames.register;
      final isLockRoute = matchedLocation == RouteNames.lock;
      final isAuthRoute = isLoginRoute || isRegisterRoute;
      final isInviteRoute = matchedLocation.startsWith('/invite');

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
        path: RouteNames.register,
        name: RouteNames.registerName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/invite/:token',
        name: 'invite',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RegisterScreen(
          invitationToken: state.pathParameters['token'],
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
          ),
          GoRoute(
            path: RouteNames.subscriptions,
            name: RouteNames.subscriptionsName,
            builder: (context, state) => const SubscriptionListScreen(),
          ),
          GoRoute(
            path: RouteNames.debts,
            name: RouteNames.debtsName,
            builder: (context, state) => const DebtListScreen(),
          ),
          GoRoute(
            path: RouteNames.shop,
            name: RouteNames.shopName,
            builder: (context, state) => const ProductListScreen(),
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
            path: RouteNames.settingsAppearance,
            name: RouteNames.settingsAppearanceName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                const AppearanceSettingsScreen(),
          ),
          GoRoute(
            path: RouteNames.settingsFeatures,
            name: RouteNames.settingsFeaturesName,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                const FeatureSettingsScreen(),
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
  Widget build(BuildContext context) {
    final featureState = ref.watch(featureConfigNotifierProvider);
    final enabledFeatures = featureState.enabledFeatures;
    final navOrder = featureState.navOrder;

    // Build dynamic paths and destinations
    final paths = <String>[
      RouteNames.dashboard,
      RouteNames.transactions,
    ];
    final destinations = <NavDestination>[
      const NavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Accueil',
      ),
      const NavDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
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
            icon: Icons.autorenew_outlined,
            selectedIcon: Icons.autorenew,
            label: 'Abonnements',
          ),
        ),
        Feature.debts => (
          RouteNames.debts,
          const NavDestination(
            icon: Icons.handshake_outlined,
            selectedIcon: Icons.handshake,
            label: 'Dettes',
          ),
        ),
        Feature.shop => (
          RouteNames.shop,
          const NavDestination(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            label: 'Boutique',
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
    } else if (state.type == ModalType.product) {
      return _ProductFormConsumer(
        product: state.entity as Product?,
        onDone: () {
          Navigator.of(context).pop();
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showModal(BuildContext context, ModalOpen state) {
    _isModalShowing = true;
    final notifier = ref.read(modalNotifierProvider.notifier);

    Widget? headerActions;
    if (state.type.hasToggle) {
      final values = state.type.toggleValues!;
      final selectedIndex = values.indexOf(state.subType);

      headerActions = _ModalToggle(
        type: state.type,
        initialIndex: selectedIndex.clamp(0, 1),
      );
    }

    final child = _buildModalChild(state);

    AppModal.show(
      context,
      title: state.type.title(state.mode),
      headerActions: headerActions,
      inlineHeaderActions: state.type.hasToggle,
      onClose: () {
        _isModalShowing = false;
        notifier.close();
      },
      child: child,
    ).then((_) {
      // Modal dismissed via swipe/overlay tap
      if (_isModalShowing) {
        _isModalShowing = false;
        notifier.close();
      }
    });
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

class _ProductFormConsumer extends ConsumerWidget {
  final Product? product;
  final VoidCallback onDone;

  const _ProductFormConsumer({
    this.product,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(modalNotifierProvider);
    if (modalState is! ModalOpen) return const SizedBox.shrink();

    return ProductForm(
      product: product,
      onSaved: (p) async {
        if (product == null) {
          await ref.read(productNotifierProvider.notifier).create(p);
        } else {
          await ref.read(productNotifierProvider.notifier).update(p);
        }
        onDone();
      },
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
