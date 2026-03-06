import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart';
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
        title: const Text('Profil'),
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
}

class _ProfileContent extends StatelessWidget {
  final User user;
  final Currency selectedCurrency;
  final ValueChanged<Currency> onCurrencyChanged;
  final ThemeData theme;

  const _ProfileContent({
    required this.user,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        _ReadOnlyField(
          label: 'Nom',
          value: user.name,
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.space6),
        _ReadOnlyField(
          label: 'Email',
          value: user.email,
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.space6),
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
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String? value;
  final ThemeData theme;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.theme,
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
      ],
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
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showCurrencyPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${selectedCurrency.symbol} — ${selectedCurrency.name}',
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
                title: Text('${currency.symbol} — ${currency.name}'),
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
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 20),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
