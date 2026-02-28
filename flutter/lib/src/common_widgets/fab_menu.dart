import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

class FabMenu extends ConsumerStatefulWidget {
  const FabMenu({super.key});

  @override
  ConsumerState<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends ConsumerState<FabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  static const _allItems = [
    _SpeedDialItem(
      icon: Icons.receipt_long,
      label: 'Transaction',
      modalType: ModalType.transaction,
    ),
    _SpeedDialItem(
      icon: Icons.autorenew,
      label: 'Abonnement',
      modalType: ModalType.subscription,
    ),
    _SpeedDialItem(
      icon: Icons.handshake,
      label: 'Dette',
      modalType: ModalType.debt,
    ),
    _SpeedDialItem(
      icon: Icons.swap_horiz,
      label: 'Virement',
      modalType: ModalType.transfer,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      setState(() => _isOpen = true);
      _controller.forward();
      _overlayEntry = OverlayEntry(
        builder: (_) => GestureDetector(
          onTap: _close,
          behavior: HitTestBehavior.opaque,
          child: const ColoredBox(
            color: Color(0x33000000),
            child: SizedBox.expand(),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _onItemTap(ModalType type) {
    _close();
    ref.read(modalNotifierProvider.notifier).open(type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountState = ref.watch(accountNotifierProvider);
    final activeAccountCount =
        accountState.items.where((a) => a.actif).length;

    final featureState = ref.watch(featureConfigNotifierProvider);
    final enabledFeatures = featureState.enabledFeatures;

    final items = _allItems
        .where((item) {
          // Keep transfer only if 2+ active accounts
          if (item.modalType == ModalType.transfer) {
            return activeAccountCount >= 2;
          }
          // Hide subscription if feature off
          if (item.modalType == ModalType.subscription) {
            return enabledFeatures.contains(Feature.subscriptions);
          }
          // Hide debt if feature off
          if (item.modalType == ModalType.debt) {
            return enabledFeatures.contains(Feature.debts);
          }
          // Transaction always visible
          return true;
        })
        .toList();

    return SizedBox(
      height: _isOpen ? 300 : 56,
      width: 160,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Speed dial items
          Positioned(
            bottom: 64,
            right: 0,
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: 1,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: items
                      .map((item) => _buildSpeedDialItem(item, theme))
                      .toList(),
                ),
              ),
            ),
          ),
          // Main FAB
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialItem(_SpeedDialItem item, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        child: InkWell(
          onTap: () => _onItemTap(item.modalType),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: 130,
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedDialItem {
  final IconData icon;
  final String label;
  final ModalType modalType;

  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.modalType,
  });
}
