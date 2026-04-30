import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/avatar_picker.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/change_password_sheet.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  Currency? _selectedCurrency;
  bool _hasChanged = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        actions: [
          if (_hasChanged)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.space4),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const PhosphorIcon(PhosphorIconsBold.check, size: 24),
                    onPressed: _save,
                  ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const ProfileSettingsSkeleton(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(userProfileNotifierProvider.notifier).loadProfile(),
        ),
        data: (user) => _ProfileContent(
          user: user,
          selectedCurrency: _selectedCurrency ?? user.defaultCurrency,
          onCurrencyChanged: (currency) {
            setState(() {
              _selectedCurrency = currency;
              _hasChanged = currency != user.defaultCurrency;
            });
          },
          theme: theme,
          onLogout: _logout,
          onChangePassword: _openChangePassword,
          onAvatarChanged: () =>
              ref.read(userProfileNotifierProvider.notifier).loadProfile(),
          onExportJson: _exportJson,
          onExportCsv: _exportCsv,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final currency = _selectedCurrency;
    if (currency == null) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(userProfileNotifierProvider.notifier)
        .updateCurrency(currency);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (success) {
        _hasChanged = false;
        _selectedCurrency = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Devise mise à jour avec succès'
              : 'Erreur lors de la mise à jour',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Résilience : déconnexion locale même si backend échoue
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  Future<void> _openChangePassword() async {
    if (!mounted) return;
    await ChangePasswordSheet.show(context);
    // Les tokens sont déjà mis à jour dans la sheet en cas de succès
  }

  Future<void> _exportJson() async {
    await _runExport(
      action: () async {
        final repo =
            await ref.read(userProfileRepositoryProvider.future);
        return repo.exportJson();
      },
      successLabel: 'Export JSON téléchargé',
    );
  }

  Future<void> _exportCsv() async {
    await _runExport(
      action: () async {
        final repo =
            await ref.read(userProfileRepositoryProvider.future);
        return repo.exportCsv();
      },
      successLabel: 'Export CSV téléchargé',
    );
  }

  Future<void> _runExport({
    required Future<dynamic> Function() action,
    required String successLabel,
  }) async {
    if (!mounted) return;
    try {
      final file = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successLabel\n${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export : $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Contenu principal
// ────────────────────────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final User user;
  final Currency selectedCurrency;
  final ValueChanged<Currency> onCurrencyChanged;
  final ThemeData theme;
  final VoidCallback onLogout;
  final VoidCallback onChangePassword;
  final VoidCallback onAvatarChanged;
  final VoidCallback onExportJson;
  final VoidCallback onExportCsv;

  const _ProfileContent({
    required this.user,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.theme,
    required this.onLogout,
    required this.onChangePassword,
    required this.onAvatarChanged,
    required this.onExportJson,
    required this.onExportCsv,
  });

  String get _initials {
    final name = user.name ?? user.email;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // ── Section Identité ──────────────────────────────────────────────
        _SectionHeader(label: 'Identité', theme: theme),
        const SizedBox(height: AppSpacing.space4),

        // Avatar
        Center(
          child: AvatarPicker(
            currentAvatarUrl: null, // TODO: wirer via avatarPath quand User expose la propriété
            userInitials: _initials,
            onUploadSuccess: onAvatarChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.space6),

        // Nom
        _ReadOnlyField(
          label: 'Nom',
          value: user.name,
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.space6),

        // Email (géré par admin)
        _ReadOnlyField(
          label: 'Email',
          value: user.email,
          subtitle: 'Géré par l\'administrateur',
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.space6),

        // Devise
        Text(
          'Devise par défaut',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _CurrencySelector(
          selectedCurrency: selectedCurrency,
          onChanged: onCurrencyChanged,
          theme: theme,
        ),

        const SizedBox(height: AppSpacing.space8),
        const Divider(),
        const SizedBox(height: AppSpacing.space4),

        // ── Section Sécurité ─────────────────────────────────────────────
        _SectionHeader(label: 'Sécurité', theme: theme),
        const SizedBox(height: AppSpacing.space3),

        _ActionRow(
          icon: PhosphorIconsRegular.lock,
          label: 'Changer le mot de passe',
          onTap: onChangePassword,
          theme: theme,
        ),

        const SizedBox(height: AppSpacing.space8),
        const Divider(),
        const SizedBox(height: AppSpacing.space4),

        // ── Section Données ──────────────────────────────────────────────
        _SectionHeader(label: 'Données', theme: theme),
        const SizedBox(height: AppSpacing.space3),

        _ActionRow(
          icon: PhosphorIconsRegular.database,
          label: 'Exporter mes données (JSON)',
          onTap: onExportJson,
          theme: theme,
        ),

        _ActionRow(
          icon: PhosphorIconsRegular.fileCsv,
          label: 'Exporter mes transactions (CSV)',
          onTap: onExportCsv,
          theme: theme,
        ),

        const SizedBox(height: AppSpacing.space8),
        const Divider(),
        const SizedBox(height: AppSpacing.space4),

        // ── Zone de danger ───────────────────────────────────────────────
        _SectionHeader(label: 'Zone de danger', theme: theme),
        const SizedBox(height: AppSpacing.space3),

        _ActionRow(
          icon: PhosphorIconsRegular.signOut,
          label: 'Déconnexion',
          onTap: onLogout,
          theme: theme,
          // Style neutre/gris (pas rouge — spec T-024)
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Widgets privés réutilisés dans l'écran
// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String? value;
  final String? subtitle;
  final ThemeData theme;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.theme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          hasValue ? value! : 'Non renseigné',
          style: hasValue
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? foregroundColor;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space2,
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final Currency selectedCurrency;
  final ValueChanged<Currency> onChanged;
  final ThemeData theme;

  const _CurrencySelector({
    required this.selectedCurrency,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _showCurrencyPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${selectedCurrency.symbol} — ${selectedCurrency.displayName}',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet<Currency>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                'Devise par défaut',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            ...Currency.values.map(
              (currency) => ListTile(
                title: Text('${currency.symbol} — ${currency.displayName}'),
                trailing: currency == selectedCurrency
                    ? PhosphorIcon(PhosphorIconsBold.check,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20)
                    : null,
                onTap: () {
                  Navigator.of(context).pop(currency);
                },
              ),
            ),
          ],
        ),
      ),
    ).then((currency) {
      if (currency != null) {
        onChanged(currency);
      }
    });
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.warning,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Impossible de charger le profil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowClockwise,
                  size: 20),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
