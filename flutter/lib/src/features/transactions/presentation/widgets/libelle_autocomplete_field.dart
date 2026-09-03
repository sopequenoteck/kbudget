// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/features/transactions/application/libelle_suggestions_provider.dart';

/// Champ de saisie du libellé avec suggestions d'autocomplete.
///
/// Basé sur [RawAutocomplete<String>] pour conserver le contrôle
/// complet du style. Les suggestions sont chargées via
/// [libelleSuggestionsProvider] avec un debounce de [debounce].
///
/// Saisie libre toujours possible (FR-009) : aucune contrainte
/// n'est imposée sur la valeur finale du champ.
class LibelleAutocompleteField extends ConsumerStatefulWidget {
  const LibelleAutocompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.validator,
    this.maxDisplay = 5,
    this.minChars = 2,
    this.debounce = const Duration(milliseconds: 200),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final int maxDisplay;
  final int minChars;
  final Duration debounce;

  @override
  ConsumerState<LibelleAutocompleteField> createState() =>
      _LibelleAutocompleteFieldState();
}

class _LibelleAutocompleteFieldState
    extends ConsumerState<LibelleAutocompleteField> {
  Timer? _debounceTimer;
  String _debouncedQuery = '';

  void _controllerListener() {
    _onTextChanged(widget.controller.text);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(covariant LibelleAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    if (text.length < widget.minChars) {
      // Annule immédiatement — pas de suggestions sous le seuil
      setState(() => _debouncedQuery = '');
      return;
    }
    _debounceTimer = Timer(widget.debounce, () {
      if (mounted) {
        setState(() => _debouncedQuery = text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode ?? FocusNode(),
      displayStringForOption: (option) => option,
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text;
        if (query.length < widget.minChars) {
          return const Iterable<String>.empty();
        }
        // On utilise la debouncedQuery pour ne pas appeler le provider
        // à chaque frappe — le Timer gère le délai.
        final suggestions = await ref
            .read(libelleSuggestionsProvider(_debouncedQuery).future)
            .catchError((_) => <String>[]);
        return suggestions.take(widget.maxDisplay);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Le listener du debounce est enregistré une seule fois dans initState
        // sur widget.controller (identique à ce controller fourni par RawAutocomplete).
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: widget.decoration ??
              const InputDecoration.collapsed(hintText: ''),
          validator: widget.validator,
          maxLength: 255,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _SuggestionsOverlay(
          options: options.toList(),
          onSelected: onSelected,
        );
      },
    );
  }
}

/// Overlay de suggestions stylé avec les tokens centralisés du projet.
class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(top: AppSpacing.space1),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.md,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.space2,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (context2, index2) => Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withAlpha(80),
                indent: AppSpacing.space4,
                endIndent: AppSpacing.space4,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                return _SuggestionItem(
                  label: option,
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 16,
              color: AppColors.gray400,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.regular,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
