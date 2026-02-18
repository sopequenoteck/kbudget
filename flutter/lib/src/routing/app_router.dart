import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/adaptive_scaffold.dart';
import 'package:k_budget/src/common_widgets/fab_menu.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
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
import 'package:k_budget/src/features/settings/presentation/settings_screen.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_list_screen.dart';
import 'package:k_budget/src/features/transactions/presentation/transaction_list_screen.dart';
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
          final isAuthenticated = authState is AuthAuthenticated;

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
        ],
      ),
      GoRoute(
        path: RouteNames.settings,
        name: RouteNames.settingsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  static const _paths = [
    RouteNames.dashboard,
    RouteNames.transactions,
    RouteNames.subscriptions,
    RouteNames.debts,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _paths.indexOf(location).clamp(0, _paths.length - 1);

    return AdaptiveScaffold(
      currentIndex: currentIndex,
      onDestinationSelected: (index) {
        context.go(_paths[index]);
      },
      floatingActionButton: const FabMenu(),
      body: child,
    );
  }
}
