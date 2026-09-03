// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/avatar_picker.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/change_password_sheet.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/delete_account_sheet.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  bool _isEditingName = false;
  bool _isSavingName = false;
  late TextEditingController _nameController;
  bool _isExportingJson = false;
  bool _isExportingCsv = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  AppThemeExtension ext(BuildContext context) =>
      Theme.of(context).extension<AppThemeExtension>()!;

  String _initials(User user) {
    final name = user.name ?? user.email;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
      ),
      body: profileAsync.when(
        loading: () => const ProfileSettingsSkeleton(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(userProfileNotifierProvider.notifier).loadProfile(),
        ),
        data: (user) => Column(
          children: [
            if (_errorMessage != null) _buildErrorBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  Center(
                    child: AvatarPicker(
                      currentAvatarUrl: null,
                      userInitials: _initials(user),
                      onUploadSuccess: () => ref
                          .read(userProfileNotifierProvider.notifier)
                          .loadProfile(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  _SettingsSection(
                    label: 'Identité',
                    children: [
                      _buildNameRow(user),
                      _SettingsRow(
                        title: user.email,
                        description: 'Géré par l\'administrateur',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  _SettingsSection(
                    label: 'Sécurité',
                    children: [
                      _SettingsRow(
                        icon: PhosphorIconsRegular.lock,
                        iconBg: ext(context).primarySubtle,
                        title: 'Changer le mot de passe',
                        onTap: _openChangePassword,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  _SettingsSection(
                    label: 'Données',
                    children: [
                      _ExportRow(
                        icon: PhosphorIconsRegular.database,
                        iconBg: ext(context).primarySubtle,
                        title: 'Exporter mes données (JSON)',
                        isLoading: _isExportingJson,
                        enabled: !_isExportingJson && !_isExportingCsv,
                        onTap: _exportJson,
                      ),
                      _ExportRow(
                        icon: PhosphorIconsRegular.fileCsv,
                        iconBg: ext(context).primarySubtle,
                        title: 'Exporter mes transactions (CSV)',
                        isLoading: _isExportingCsv,
                        enabled: !_isExportingJson && !_isExportingCsv,
                        onTap: _exportCsv,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  _SettingsSection(
                    label: 'Zone de danger',
                    children: [
                      _SettingsRow(
                        title: 'Déconnexion',
                        onTap: _logout,
                      ),
                      _SettingsRow(
                        title: 'Supprimer mon compte',
                        titleColor: Theme.of(context).colorScheme.error,
                        onTap: _openDeleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow(User user) {
    if (_isEditingName) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppSpacing.space2,
                    horizontal: AppSpacing.space2,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            if (_isSavingName)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.check, size: 20),
                onPressed: _saveName,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Theme.of(context).colorScheme.primary,
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 20),
                onPressed: () => setState(() => _isEditingName = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      );
    }

    return _SettingsRow(
      title: user.name ?? 'Non renseigné',
      trailing: IconButton(
        icon: const PhosphorIcon(PhosphorIconsRegular.pencil, size: 18),
        onPressed: () => setState(() {
          _nameController.text = user.name ?? '';
          _isEditingName = true;
        }),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.warning,
            size: 16,
            color: colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 100) return;

    setState(() {
      _errorMessage = null;
      _isSavingName = true;
    });

    try {
      final repo = await ref.read(userProfileRepositoryProvider.future);
      await repo.updateName(name);
      await ref.read(userProfileNotifierProvider.notifier).loadProfile();
      if (!mounted) return;
      setState(() {
        _isEditingName = false;
        _isSavingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingName = false;
        _errorMessage = 'Impossible de mettre à jour le nom';
      });
    }
  }

  Future<void> _exportJson() async {
    setState(() {
      _errorMessage = null;
      _isExportingJson = true;
    });
    try {
      final repo = await ref.read(userProfileRepositoryProvider.future);
      await repo.exportJson();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur lors de l\'export JSON');
    } finally {
      if (mounted) setState(() => _isExportingJson = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _errorMessage = null;
      _isExportingCsv = true;
    });
    try {
      final repo = await ref.read(userProfileRepositoryProvider.future);
      await repo.exportCsv();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur lors de l\'export CSV');
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  Future<void> _openChangePassword() async {
    setState(() => _errorMessage = null);
    if (!mounted) return;
    await ChangePasswordSheet.show(context);
  }

  Future<void> _openDeleteAccount() async {
    setState(() => _errorMessage = null);
    if (!mounted) return;
    await DeleteAccountSheet.show(context);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Widgets privés
// ────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
        ),
        const SizedBox(height: AppSpacing.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                        height: 0,
                        thickness: 0.5,
                        color: colorScheme.outlineVariant),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final PhosphorIconData? icon;
  final Color? iconBg;
  final String title;
  final Color? titleColor;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsRow({
    this.icon,
    this.iconBg,
    required this.title,
    this.titleColor,
    this.description,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = titleColor ?? colorScheme.onSurface;

    Widget? iconWidget;
    if (icon != null) {
      iconWidget = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBg ?? colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: PhosphorIcon(icon!, size: 18, color: effectiveColor),
        ),
      );
    }

    final defaultTrailing = onTap != null
        ? PhosphorIcon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          )
        : null;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            if (iconWidget != null) ...[
              iconWidget,
              const SizedBox(width: AppSpacing.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: effectiveColor,
                        ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            trailing ?? defaultTrailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconBg;
  final String title;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _ExportRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SettingsRow(
      icon: icon,
      iconBg: iconBg,
      title: title,
      description: isLoading ? 'Téléchargement en cours…' : null,
      enabled: enabled,
      onTap: onTap,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
    );
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
                size: 20,
              ),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
