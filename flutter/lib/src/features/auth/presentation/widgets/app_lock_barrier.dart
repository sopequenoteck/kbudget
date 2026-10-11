// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/app_lock_state.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/lock_screen.dart';
import 'package:k_budget/src/routing/route_names.dart';

/// Covers the whole app with the lock screen while it is locked.
///
/// Placed in the `builder` of `MaterialApp.router`, above the navigator, so no
/// route or deep link goes around it. It applies to a session that holds valid
/// tokens: an authenticated one, or one that must reset its credentials (the
/// first-login screen can change the e-mail and the password with the session
/// in progress). Server setup, sign-in, invitation and the incompatibility
/// screen are never covered.
///
/// While the lock state is still unknown, a plain background is shown: the app
/// is never visible before it is known whether it is locked. The covered app
/// stays mounted, so it comes back as it was left, but it is not painted, not
/// reachable by touch and not in the semantics tree.
///
/// When the session ends while the app is covered (fifth wrong PIN, "Forgot
/// PIN"), the covered screen is still mounted until the router, whose redirect
/// is asynchronous, has left it. The barrier keeps hiding the app behind the
/// plain background until the router's location changes or the session holds
/// tokens again. After [lockHoldTimeout] without a change, the router is sent
/// to the sign-in screen, and the app stays hidden until it gets there. A
/// sign-out made while the app was not covered is not held.
///
/// It also forwards the app lifecycle to the lock, which decides when to lock
/// again.
class AppLockBarrier extends ConsumerStatefulWidget {
  /// Creates the barrier around [child], the navigator of the app, which
  /// [router] drives.
  const AppLockBarrier({required this.child, required this.router, super.key});

  /// The app to protect.
  final Widget child;

  /// The router of the app, to tell when it has left the covered screen.
  final GoRouter router;

  @override
  ConsumerState<AppLockBarrier> createState() => _AppLockBarrierState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Widget>('child', child))
      ..add(DiagnosticsProperty<GoRouter>('router', router));
  }
}

class _AppLockBarrierState extends ConsumerState<AppLockBarrier>
    with WidgetsBindingObserver {
  Timer? _holdTimer;
  var _coveredAtLastBuild = false;
  var _holding = false;
  String? _heldLocation;

  String get _location =>
      widget.router.routerDelegate.currentConfiguration.uri.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(AppLockBarrier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    _holdTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ref.read(appLockNotifierProvider.notifier).onLifecycleChanged(state);

  bool _isProtected(AuthState auth) =>
      auth is AuthAuthenticated || auth is AuthPasswordResetRequired;

  bool get _isCovered =>
      _isProtected(ref.read(authNotifierProvider)) &&
      ref.read(appLockNotifierProvider).status != LockStatus.unlocked;

  // The software keyboard must not stay open over the lock screen.
  void _dropFocusIfCovered() {
    if (_isCovered) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
    _dropFocusIfCovered();
    if (_coveredAtLastBuild &&
        previous != null &&
        _isProtected(previous) &&
        !_isProtected(next)) {
      // The state change also rebuilds this widget, which then reads the hold.
      _holding = true;
      _heldLocation = _location;
      _holdTimer?.cancel();
      _holdTimer = Timer(lockHoldTimeout, _sendToSignIn);
    }
  }

  void _onRouteChanged() {
    if (_holding && _location != _heldLocation) {
      _endHold();
    }
  }

  // The router did not leave the covered screen in time: send it to the
  // sign-in screen, and keep hiding the app until the location has changed.
  void _sendToSignIn() {
    _holdTimer = null;
    if (_holding) {
      widget.router.go(RouteNames.login);
    }
  }

  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_holding && mounted) {
      setState(() => _holding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(authNotifierProvider, _onAuthChanged)
      ..listen(appLockNotifierProvider, (_, _) => _dropFocusIfCovered());
    final protected = _isProtected(ref.watch(authNotifierProvider));
    final status = ref.watch(
      appLockNotifierProvider.select((state) => state.status),
    );
    if (protected && _holding) {
      _holding = false;
      _holdTimer?.cancel();
    }
    final covered = protected && status != LockStatus.unlocked;
    _coveredAtLastBuild = covered;
    final hidden = covered || _holding;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: hidden, child: widget.child),
        if (hidden)
          if (_holding || status == LockStatus.unknown)
            ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)
          else
            // Its own navigator: the dialogs of the lock screen need one, and
            // this widget sits above the app's. It must not share the app's
            // hero controller, which only one navigator can use.
            HeroControllerScope.none(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const LockScreen(),
                ),
              ),
            ),
      ],
    );
  }
}
