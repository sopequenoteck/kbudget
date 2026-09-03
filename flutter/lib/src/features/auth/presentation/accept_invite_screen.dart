import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Provider public (sans intercepteur auth) pour le lookup invitation
final _invitationLookupProvider =
    FutureProvider.family<String, String>((ref, token) async {
  final dio = await ref.watch(apiClientProvider.future);
  final response =
      await dio.get<Map<String, dynamic>>('/auth/invitations/$token');
  return response.data!['email'] as String;
});

class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String token;

  const AcceptInviteScreen({super.key, required this.token});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;
  String _selectedCurrency = 'EUR';

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(String email) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final dio = await ref.read(apiClientProvider.future);
      final dataSource = AuthRemoteDataSource(dio);
      final repo = AuthRepositoryImpl(dataSource);

      final timezone = DateTime.now().timeZoneName;

      // Appeler le endpoint accept-invite directement
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/accept-invite',
        data: {
          'token': widget.token,
          'password': _passwordController.text,
          'displayName': _displayNameController.text.trim(),
          'currency': _selectedCurrency,
          'timezone': timezone,
        },
      );

      final accessToken = response.data!['token'] as String;
      final refreshToken = response.data!['refreshToken'] as String;

      // Sauvegarder les tokens
      await repo.saveTokens(accessToken, refreshToken);

      // Marquer comme authentifié
      ref.read(authNotifierProvider.notifier).forceUnauthenticated();
      // Re-vérifier l'auth pour mettre à jour l'état
      await ref.read(authNotifierProvider.notifier).checkAuth();

      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } on DioException catch (e) {
      setState(() {
        _isSubmitting = false;
        if (e.response?.statusCode == 404) {
          _submitError =
              'Le lien d\'invitation est invalide, expiré ou déjà utilisé.';
        } else {
          _submitError =
              'Erreur lors de la création du compte. Veuillez réessayer.';
        }
      });
    } on Exception catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Erreur inattendue: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(_invitationLookupProvider(widget.token));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: lookupAsync.when(
                loading: () => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.space4),
                    Text('Vérification de l\'invitation…'),
                  ],
                ),
                error: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.warning,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'Lien invalide',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Ce lien d\'invitation est invalide, expiré, déjà utilisé ou révoqué.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    FilledButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                ),
                data: (email) => _buildForm(context, email),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, String email) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.sealCheck,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Créer votre compte',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Complétez votre profil pour rejoindre l\'instance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space8),
          // Email lecture seule
          TextFormField(
            initialValue: email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: PhosphorIcon(
                PhosphorIconsRegular.envelope,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextFormField(
            controller: _displayNameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Nom d\'affichage',
              prefixIcon: PhosphorIcon(
                PhosphorIconsRegular.user,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.space4),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const PhosphorIcon(
                PhosphorIconsRegular.lock,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: PhosphorIcon(
                  _obscurePassword
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              helperText: PasswordPolicy.helperText,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir un mot de passe';
              }
              if (value.length < PasswordPolicy.minLength) {
                return PasswordPolicy.tooShortMessage;
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSubmit(email),
          ),
          const SizedBox(height: AppSpacing.space4),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Devise principale',
              prefixIcon: PhosphorIcon(
                PhosphorIconsRegular.currencyCircleDollar,
                size: 20,
              ),
            ),
            items: Currency.values.map((currency) {
              return DropdownMenuItem<String>(
                value: currency.name.toUpperCase(),
                child: Text('${currency.symbol} - ${currency.displayName}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCurrency = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.space6),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: Text(
                _submitError!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _isSubmitting ? null : () => _handleSubmit(email),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer mon compte'),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed:
                _isSubmitting ? null : () => context.go(RouteNames.login),
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }
}
