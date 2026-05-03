import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

class InvitationListItem extends StatelessWidget {
  final Invitation invitation;
  final bool isMutating;
  final VoidCallback? onCopyLink;
  final VoidCallback? onRevoke;

  const InvitationListItem({
    super.key,
    required this.invitation,
    this.isMutating = false,
    this.onCopyLink,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = invitation.status == InvitationStatus.active;

    return ListTile(
      title: Text(
        invitation.email,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        'Par ${invitation.invitedByEmail}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isMutating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InvitationStatusBadge(status: invitation.status),
                if (isActive && invitation.token != null) ...[
                  const SizedBox(width: AppSpacing.space1),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Copier le lien',
                    onPressed: onCopyLink,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Révoquer',
                    onPressed: onRevoke,
                  ),
                ],
              ],
            ),
    );
  }
}

class _InvitationStatusBadge extends StatelessWidget {
  final InvitationStatus status;

  const _InvitationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InvitationStatus.active => ('Actif', AppColors.success),
      InvitationStatus.expired => ('Expiré', AppColors.warning),
      InvitationStatus.used => ('Utilisé', AppColors.info),
      InvitationStatus.revoked => ('Révoqué', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.space1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
