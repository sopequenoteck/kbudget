// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/settings/application/language_notifier.dart';
import 'package:k_budget/src/features/settings/application/text_scale_notifier.dart';
import 'package:k_budget/src/features/settings/application/theme_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// HealthCheckResult — sealed union pour l'état du health check serveur
// ---------------------------------------------------------------------------

sealed class HealthCheckResult {
  const HealthCheckResult();
  const factory HealthCheckResult.checking() = _Checking;
  const factory HealthCheckResult.online({required int responseTimeMs}) =
      _Online;
  const factory HealthCheckResult.offline() = _Offline;
}

class _Checking extends HealthCheckResult {
  const _Checking();
}

class _Online extends HealthCheckResult {
  final int responseTimeMs;
  const _Online({required this.responseTimeMs});
}

class _Offline extends HealthCheckResult {
  const _Offline();
}

// ---------------------------------------------------------------------------
// SettingsHubScreen
// ---------------------------------------------------------------------------

class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  PackageInfo? _packageInfo;
  HealthCheckResult _healthResult = const HealthCheckResult.checking();

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
    unawaited(_runHealthCheck());
  }

  Future<void> _runHealthCheck() async {
    final serverUrl = ref.read(dataSettingsNotifierProvider).serverUrl;
    if (serverUrl == null) {
      if (mounted) setState(() => _healthResult = const HealthCheckResult.offline());
      return;
    }
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    try {
      final healthUrl = serverUrl.endsWith('/')
          ? '${serverUrl}actuator/health'
          : '$serverUrl/actuator/health';
      final stopwatch = Stopwatch()..start();
      final response = await dio.get(healthUrl);
      stopwatch.stop();
      final ok = response.statusCode != null && response.statusCode! < 500;
      if (mounted) {
        setState(() {
          _healthResult = ok
              ? HealthCheckResult.online(
                  responseTimeMs: stopwatch.elapsedMilliseconds)
              : const HealthCheckResult.offline();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _healthResult = const HealthCheckResult.offline());
      }
    }
  }

  // -------------------------------------------------------------------------
  // Reorder helpers
  // -------------------------------------------------------------------------

  void _onReorder(int oldIndex, int newIndex, FeatureConfigState featureState) {
    final enabledOrdered = featureState.navOrder
        .where((f) => featureState.enabledFeatures.contains(f))
        .toList();
    if (oldIndex < newIndex) newIndex -= 1;
    final item = enabledOrdered.removeAt(oldIndex);
    enabledOrdered.insert(newIndex, item);

    final newNavOrder = <Feature>[];
    var enabledIdx = 0;
    for (final f in featureState.navOrder) {
      if (featureState.enabledFeatures.contains(f)) {
        newNavOrder.add(enabledOrdered[enabledIdx++]);
      } else {
        newNavOrder.add(f);
      }
    }
    ref
        .read(featureConfigNotifierProvider.notifier)
        .reorderNavigation(newNavOrder);
  }

  Future<void> _onToggleFeature(Feature feature, bool isCurrentlyEnabled) async {
    if (isCurrentlyEnabled && _hasExistingData(feature)) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await ConfirmDialogCustom.show(
        context: context,
        icon: PhosphorIconsRegular.warning,
        title: l10n.settingsDialogDisableFeatureTitle(
          _featureName(feature, l10n),
        ),
        message: l10n.settingsDialogDisableFeatureMessage,
        confirmLabel: l10n.commonActionDisable,
        variant: ConfirmVariant.danger,
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    await ref
        .read(featureConfigNotifierProvider.notifier)
        .toggleFeature(feature);
  }

  bool _hasExistingData(Feature feature) {
    return switch (feature) {
      Feature.subscriptions =>
        ref.read(subscriptionNotifierProvider).items.isNotEmpty,
      Feature.debts => ref.read(debtNotifierProvider).items.isNotEmpty,
      Feature.budgets => ref.read(budgetNotifierProvider).items.isNotEmpty,
    };
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final themeMode = ref.watch(themeNotifierProvider);
    final textScale = ref.watch(textScaleNotifierProvider);
    final featureState = ref.watch(featureConfigNotifierProvider);
    final userAsync = ref.watch(userProfileNotifierProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final l10n = AppLocalizations.of(context)!;

    ref.listen(featureConfigNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final enabledOrdered = featureState.navOrder
        .where((f) => featureState.enabledFeatures.contains(f))
        .toList();
    final disabledFeatures = Feature.values
        .where((f) => !featureState.enabledFeatures.contains(f))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonNavSettings)),
      body: CustomScrollView(
        slivers: [
          // ----------------------------------------------------------------
          // Section Compte
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space6,
              ),
              child: _buildAccountSection(context, userAsync),
            ),
          ),

          // ----------------------------------------------------------------
          // Section Gestion
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSectionLabel(l10n.settingsPageManagementTitle),
                  const SizedBox(height: AppSpacing.space2),
                  _SettingsRow(
                    icon: PhosphorIconsRegular.user,
                    iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    iconColor: theme.colorScheme.primary,
                    title: l10n.usersListProfile,
                    description: l10n.usersListProfileHint,
                    onTap: () => context.push('${RouteNames.settings}/${RouteNames.settingsProfile}'),
                  ),
                  _SettingsRow(
                    icon: PhosphorIconsRegular.bank,
                    iconBgColor: (ext?.incomeColor ?? AppColors.incomeDark).withValues(alpha: 0.15),
                    iconColor: ext?.incomeColor ?? AppColors.incomeDark,
                    title: l10n.settingsListAccounts,
                    description: l10n.settingsListAccountsHint,
                    onTap: () => context.push('${RouteNames.settings}/${RouteNames.settingsAccounts}'),
                  ),
                  _SettingsRow(
                    icon: PhosphorIconsRegular.tag,
                    iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    iconColor: theme.colorScheme.primary,
                    title: l10n.settingsListCategories,
                    description: l10n.settingsListCategoriesHint,
                    onTap: () => context.push('${RouteNames.settings}/${RouteNames.settingsCategories}'),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Section Administration (admin seulement)
          // ----------------------------------------------------------------
          if (isAdmin)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.space6),
                    _SettingsSectionLabel(
                      l10n.settingsPageAdministrationTitle,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    _SettingsRow(
                      icon: PhosphorIconsRegular.users,
                      iconBgColor: (ext?.secondaryColor ?? AppColors.indigo500).withValues(alpha: 0.15),
                      iconColor: ext?.secondaryColor ?? AppColors.indigo500,
                      title: l10n.usersPageAdminTitle,
                      description: l10n.usersListManageHint,
                      onTap: () => context.push(RouteNames.adminUsers),
                    ),
                  ],
                ),
              ),
            ),

          // ----------------------------------------------------------------
          // Section Apparence
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space6),
                  _SettingsSectionLabel(l10n.settingsPageAppearanceTitle),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    l10n.settingsFormTheme,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeOption(
                          icon: PhosphorIconsRegular.sun,
                          label: l10n.settingsValueThemeLight,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: _ThemeOption(
                          icon: PhosphorIconsRegular.moon,
                          label: l10n.settingsValueThemeDark,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: _ThemeOption(
                          icon: PhosphorIconsRegular.circleHalf,
                          label: l10n.settingsValueThemeAuto,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    l10n.settingsFormTextScale,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      for (final scale in TextScale.values) ...[
                        if (scale != TextScale.values.first)
                          const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: _ScaleOption(
                            scale: scale,
                            isSelected: textScale == scale,
                            onTap: () => ref
                                .read(textScaleNotifierProvider.notifier)
                                .setTextScale(scale),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      l10n.settingsListTextScalePreview,
                      style: TextStyle(
                        fontSize:
                            AppTypography.sizeMd * textScale.scaleFactor,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const _LanguageSelector(),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Section Navigation
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space6),
                  _SettingsSectionLabel(l10n.settingsPageNavigationTitle),
                  const SizedBox(height: AppSpacing.space2),

                  // Items verrouillés
                  Opacity(
                    opacity: 0.5,
                    child: Column(
                      children: [
                        _NavFeatureLockedItem(
                          icon: PhosphorIconsRegular.house,
                          label: l10n.commonNavHome,
                          theme: theme,
                        ),
                        _NavFeatureLockedItem(
                          icon: PhosphorIconsRegular.receipt,
                          label: l10n.commonNavTransactions,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),

                  // Features actives — réordonnables
                  if (enabledOrdered.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: child,
                        );
                      },
                      itemCount: enabledOrdered.length,
                      itemBuilder: (context, index) {
                        final feature = enabledOrdered[index];
                        return _NavFeatureActiveItem(
                          key: ValueKey(feature),
                          feature: feature,
                          index: index,
                          theme: theme,
                          onToggle: () =>
                              _onToggleFeature(feature, true),
                        );
                      },
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(oldIndex, newIndex, featureState),
                    ),

                  // Features désactivées
                  if (disabledFeatures.isNotEmpty)
                    Opacity(
                      opacity: 0.5,
                      child: Column(
                        children: disabledFeatures
                            .map(
                              (feature) => _NavFeatureDisabledItem(
                                feature: feature,
                                theme: theme,
                                onToggle: () =>
                                    _onToggleFeature(feature, false),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Section Notifications
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space6),
                  _SettingsSectionLabel(
                    l10n.settingsPageNotificationsTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildNotificationToggles(context, featureState),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Section Serveur
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space6),
                  _SettingsSectionLabel(l10n.settingsPageServerTitle),
                  const SizedBox(height: AppSpacing.space2),
                  _SettingsRow(
                    icon: PhosphorIconsRegular.hardDrives,
                    iconBgColor: ext?.iconCircleBg ??
                        theme.colorScheme.surfaceContainerHighest,
                    iconColor: theme.colorScheme.onSurfaceVariant,
                    title: l10n.settingsPageServerTitle,
                    description: l10n.settingsListServerHint,
                    onTap: () => context.push(
                      '${RouteNames.settings}/${RouteNames.settingsData}',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Footer
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space8,
              ),
              child: _buildFooter(context),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section builders
  // -------------------------------------------------------------------------

  Widget _buildAccountSection(
    BuildContext context,
    AsyncValue<User> userAsync,
  ) {
    final theme = Theme.of(context);
    final user = userAsync.valueOrNull;

    // Initiales
    String initials = '';
    if (user?.name != null && user!.name!.isNotEmpty) {
      final words = user.name!.trim().split(' ');
      initials = words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    } else if (user?.email != null) {
      initials = user!.email.substring(0, 1).toUpperCase();
    }

    return GestureDetector(
      onTap: () => context.push(
        '${RouteNames.settings}/${RouteNames.settingsProfile}',
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontSize: AppTypography.sizeXl,
                fontWeight: AppTypography.semiBold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          if (user?.name != null)
            Text(
              user!.name!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          Text(
            user?.email ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggles(
    BuildContext context,
    FeatureConfigState featureState,
  ) {
    final notifier = ref.read(featureConfigNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final enabledNotifTypes = featureState.enabledNotificationTypes;

    // Types filtrés selon les features actives
    final visibleTypes = NotificationType.values.where((type) {
      return switch (type) {
        NotificationType.subscriptionDue =>
          featureState.enabledFeatures.contains(Feature.subscriptions),
        NotificationType.debtDue ||
        NotificationType.debtReminder =>
          featureState.enabledFeatures.contains(Feature.debts),
        _ => true,
      };
    }).toList();

    return Column(
      children: [
        ...visibleTypes.map((type) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_notificationTypeName(type, l10n)),
              secondary: PhosphorIcon(type.icon, size: 22),
              value: enabledNotifTypes.contains(type),
              onChanged: (value) {
                final updated = List<NotificationType>.of(enabledNotifTypes);
                if (value) {
                  updated.add(type);
                } else {
                  updated.remove(type);
                }
                notifier.updateNotificationTypes(updated);
              },
            )),
        const SizedBox(height: AppSpacing.space4),
        _SettingsSectionLabel(l10n.settingsPageTimezoneTitle),
        const SizedBox(height: AppSpacing.space2),
        _TimezoneDropdown(
          current: featureState.timezone,
          onChanged: (tz) => notifier.updateTimezone(tz),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final version = _packageInfo?.version ?? '...';
    final l10n = AppLocalizations.of(context)!;
    final versionLabel = l10n.settingsListVersion(version);

    // Afficher le statut du health check
    final statusText = switch (_healthResult) {
      _Checking() => l10n.settingsValueChecking,
      _Online(responseTimeMs: final ms) =>
        '${l10n.settingsValueOnline} · ${ms}ms',
      _Offline() => l10n.settingsValueOffline,
    };
    final statusColor = switch (_healthResult) {
      _Checking() => theme.colorScheme.onSurfaceVariant,
      _Online() => ext?.incomeColor ?? AppColors.incomeDark,
      _Offline() => ext?.expenseColor ?? AppColors.expenseDark,
    };

    return Center(
      child: Text(
        '$versionLabel · $statusText',
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          color: statusColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  const _SettingsSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: AppTypography.sizeXs,
        fontWeight: AppTypography.semiBold,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: AppTypography.labelLetterSpacingForSize12,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconBgColor,
              child: PhosphorIcon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Language choices, automatic (`null`) first.
const _languageOptions = <String?>[null, 'en', 'fr'];

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preference = ref.watch(
      languageNotifierProvider.select((state) => state.preference),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsFormLanguage,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            for (final (index, code) in _languageOptions.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: _ThemeOption(
                  icon: code == null
                      ? PhosphorIconsRegular.globe
                      : PhosphorIconsRegular.translate,
                  label: code == null
                      ? l10n.settingsValueLanguageAuto
                      : languageNativeNames[code]!,
                  isSelected: preference == code,
                  onTap: () => unawaited(
                    ref
                        .read(languageNotifierProvider.notifier)
                        .selectLanguage(code),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight:
                    isSelected ? AppTypography.semiBold : AppTypography.regular,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.space1),
              PhosphorIcon(
                PhosphorIconsFill.checkCircle,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScaleOption extends StatelessWidget {
  final TextScale scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScaleOption({
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontSize: AppTypography.sizeMd * scale.scaleFactor,
                fontWeight: AppTypography.semiBold,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              _textScaleName(scale, AppLocalizations.of(context)!),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight:
                    isSelected ? AppTypography.semiBold : AppTypography.regular,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.space1),
              PhosphorIcon(
                PhosphorIconsFill.checkCircle,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavFeatureLockedItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final ThemeData theme;

  const _NavFeatureLockedItem({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: PhosphorIcon(icon, color: theme.colorScheme.outline, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(color: theme.colorScheme.outline),
      ),
      trailing: PhosphorIcon(
        PhosphorIconsRegular.lock,
        color: theme.colorScheme.outline,
        size: 18,
      ),
    );
  }
}

class _NavFeatureActiveItem extends StatelessWidget {
  final Feature feature;
  final int index;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _NavFeatureActiveItem({
    super.key,
    required this.feature,
    required this.index,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: PhosphorIcon(
          feature.icon,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(_featureName(feature, AppLocalizations.of(context)!)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: true,
            onChanged: (_) => onToggle(),
          ),
          ReorderableDragStartListener(
            index: index,
            child: PhosphorIcon(
              PhosphorIconsRegular.dotsSixVertical,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavFeatureDisabledItem extends StatelessWidget {
  final Feature feature;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _NavFeatureDisabledItem({
    required this.feature,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: PhosphorIcon(
          feature.outlinedIcon,
          color: theme.colorScheme.outline,
          size: 20,
        ),
      ),
      title: Text(
        _featureName(feature, AppLocalizations.of(context)!),
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Switch(
        value: false,
        onChanged: (_) => onToggle(),
      ),
    );
  }
}

class _TimezoneDropdown extends StatelessWidget {
  static const _timezones = [
    'Europe/Paris',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Madrid',
    'Europe/Rome',
    'Europe/Brussels',
    'Africa/Casablanca',
    'Africa/Lome',
    'Africa/Tunis',
    'Africa/Lagos',
    'Africa/Abidjan',
    'America/New_York',
    'America/Chicago',
    'America/Los_Angeles',
    'Asia/Tokyo',
  ];

  final String current;
  final void Function(String tz) onChanged;

  const _TimezoneDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Ensure current value is in the list to avoid assertion errors
    final safeValue = _timezones.contains(current) ? current : _timezones.first;
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: l10n.settingsPageTimezoneTitle,
        helperText: l10n.settingsFormTimezoneHint,
      ),
      items: _timezones
          .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

String _textScaleName(TextScale scale, AppLocalizations l10n) =>
    switch (scale) {
      TextScale.small => l10n.settingsValueTextScaleSmall,
      TextScale.medium => l10n.settingsValueTextScaleMedium,
      TextScale.large => l10n.settingsValueTextScaleLarge,
    };

String _notificationTypeName(NotificationType type, AppLocalizations l10n) =>
    switch (type) {
      NotificationType.subscriptionDue =>
        l10n.notificationsValueSubscriptionDue,
      NotificationType.debtDue => l10n.notificationsValueDebtDue,
      NotificationType.debtReminder => l10n.notificationsValueDebtReminder,
      NotificationType.recurringTransactionDue =>
        l10n.notificationsValueRecurringTransactionDue,
      NotificationType.budgetThreshold =>
        l10n.notificationsValueBudgetThreshold,
      NotificationType.budgetExceeded => l10n.notificationsValueBudgetExceeded,
    };

String _featureName(Feature feature, AppLocalizations l10n) =>
    switch (feature) {
      Feature.subscriptions => l10n.commonNavSubscriptions,
      Feature.debts => l10n.commonNavDebts,
      Feature.budgets => l10n.commonNavBudgets,
    };
