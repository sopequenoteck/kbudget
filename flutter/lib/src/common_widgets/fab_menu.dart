import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';

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

  static const _items = [
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
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _onItemTap(ModalType type) {
    _toggle();
    ref.read(modalNotifierProvider.notifier).open(type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  children: _items
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
