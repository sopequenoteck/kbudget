import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_typography.dart';

class DashboardHeader extends StatelessWidget {
  final String? userName;

  const DashboardHeader({
    super.key,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String greeting =
        userName != null ? 'Bonjour $userName' : 'Bonjour';

    return Text(
      greeting,
      style: TextStyle(
        fontSize: AppTypography.sizeXl,
        fontWeight: AppTypography.semiBold,
        color: colorScheme.onSurface,
      ),
    );
  }
}
