import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';

class AppModal {
  AppModal._();

  static const double _tabletBreakpoint = 768;
  static const double _dialogMaxWidth = 480;

  /// Affiche une modale : bottom sheet sur mobile, dialog sur tablette.
  static Future<void> show(
    BuildContext context, {
    required Widget child,
    required String title,
    Widget? headerActions,
    required VoidCallback onClose,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < _tabletBreakpoint) {
      return _showBottomSheet(
        context,
        child: child,
        title: title,
        headerActions: headerActions,
        onClose: onClose,
      );
    } else {
      return _showDialog(
        context,
        child: child,
        title: title,
        headerActions: headerActions,
        onClose: onClose,
      );
    }
  }

  static Future<void> _showBottomSheet(
    BuildContext context, {
    required Widget child,
    required String title,
    Widget? headerActions,
    required VoidCallback onClose,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) {
        return _ModalContent(
          title: title,
          headerActions: headerActions,
          onClose: onClose,
          child: child,
        );
      },
    );
  }

  static Future<void> _showDialog(
    BuildContext context, {
    required Widget child,
    required String title,
    Widget? headerActions,
    required VoidCallback onClose,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
            child: Material(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              clipBehavior: Clip.antiAlias,
              child: _ModalContent(
                title: title,
                headerActions: headerActions,
                onClose: onClose,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModalContent extends StatelessWidget {
  final String title;
  final Widget? headerActions;
  final VoidCallback onClose;
  final Widget child;

  const _ModalContent({
    required this.title,
    this.headerActions,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Semantics(
      label: title,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle (bottom sheet only)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.space2),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space3,
                  AppSpacing.space2,
                  AppSpacing.space2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Fermer',
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onClose();
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    if (headerActions != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      headerActions!,
                    ],
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
