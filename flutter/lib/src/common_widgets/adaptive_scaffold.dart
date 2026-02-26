import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/common_widgets/user_menu_button.dart';

class AdaptiveScaffold extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final Widget? floatingActionButton;

  static const double _breakpoint = 768;

  static const List<_Destination> _destinations = [
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Accueil',
    ),
    _Destination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Transactions',
    ),
    _Destination(
      icon: Icons.autorenew_outlined,
      selectedIcon: Icons.autorenew,
      label: 'Abonnements',
    ),
    _Destination(
      icon: Icons.handshake_outlined,
      selectedIcon: Icons.handshake,
      label: 'Dettes',
    ),
  ];

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _sidebarExpanded = true;

  static const double _sidebarExpandedWidth = 220;
  static const double _sidebarCollapsedWidth = 64;

  Widget _buildLogo({double height = 32}) {
    return SvgPicture.asset(
      'assets/budget-icon-no-background.svg',
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AdaptiveScaffold._breakpoint) {
          return _buildWideLayout(context);
        }
        return _buildNarrowLayout(context);
      },
    );
  }

  // ──────────────────────────────
  // Mobile layout
  // ──────────────────────────────

  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(width: 8),
            Text(
              'K-Budget',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        actions: const [
          UserMenuButton(),
          SizedBox(width: 8),
        ],
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onDestinationSelected,
        items: AdaptiveScaffold._destinations
            .map(
              (d) => BottomNavigationBarItem(
                icon: Icon(d.icon),
                activeIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }

  // ──────────────────────────────
  // Tablet / Desktop layout
  // ──────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final sidebarWidth =
        _sidebarExpanded ? _sidebarExpandedWidth : _sidebarCollapsedWidth;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(height: 28),
              const SizedBox(width: 8),
              Text(
                'K-Budget',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: const [
          UserMenuButton(),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            child: Material(
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Navigation items
                  ...AdaptiveScaffold._destinations.asMap().entries.map(
                        (entry) => _buildSidebarItem(
                          theme,
                          entry.value,
                          entry.key,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    ThemeData theme,
    _Destination destination,
    int index,
  ) {
    final isSelected = index == widget.currentIndex;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;
    final icon =
        isSelected ? destination.selectedIcon : destination.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onDestinationSelected(index),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExpanded ? 12 : 0,
              vertical: 10,
            ),
            child: _sidebarExpanded
                ? Row(
                    children: [
                      Icon(icon, size: 22, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(icon, size: 22, color: color),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
