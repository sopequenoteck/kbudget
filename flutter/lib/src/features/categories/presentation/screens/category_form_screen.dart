import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_preview_card.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  bool get _isEditMode => widget.category != null;

  late String _selectedEmoji;
  late String _selectedColor;

  final _nameController = TextEditingController();

  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final c = widget.category!;
      _selectedEmoji = c.icone;
      _selectedColor = c.couleur;
      _nameController.text = c.nom;
    } else {
      _selectedEmoji = '';
      _selectedColor = ColorPalettePicker.paletteColors[
          Random().nextInt(ColorPalettePicker.paletteColors.length)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateNom(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value.trim().isEmpty) return l10n.categoryNameRequired;
    if (value.length > 30) return l10n.categoryNameMaxLength;
    return null;
  }

  String? _validateEmoji() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedEmoji.isEmpty) return l10n.categoryEmojiRequired;
    return null;
  }

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);

    final nomError = _validateNom(_nameController.text);
    final emojiError = _validateEmoji();

    if (nomError != null || emojiError != null) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(categoryNotifierProvider.notifier);

    try {
      if (_isEditMode) {
        final updated = widget.category!.copyWith(
          nom: _nameController.text.trim(),
          icone: _selectedEmoji,
          couleur: _selectedColor,
        );
        await notifier.update(updated);
      } else {
        final category = Category(
          id: '',
          nom: _nameController.text.trim(),
          icone: _selectedEmoji,
          couleur: _selectedColor,
        );
        await notifier.create(category);
      }

      if (mounted) context.pop();
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final isDuplicate = e.toString().contains('409') ||
            e.toString().toLowerCase().contains('duplicate') ||
            e.toString().toLowerCase().contains('existe');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicate
                  ? l10n.categoryNameDuplicate
                  : _isEditMode
                      ? l10n.categoryErrorUpdate
                      : l10n.categoryErrorCreate,
            ),
          ),
        );
      }
    }
  }

  void _onDelete() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoryDeleteConfirmTitle),
        content: Text(l10n.categoryDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      try {
        await ref
            .read(categoryNotifierProvider.notifier)
            .delete(widget.category!.id);
        if (mounted) context.pop();
      } on Exception {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.categoryErrorDelete)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final nomError =
        _showErrors ? _validateNom(_nameController.text) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? l10n.categoryFormTitleEdit
              : l10n.categoryFormTitleCreate,
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.space4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsBold.check, size: 24),
              onPressed: _onSubmit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Preview card
          CategoryPreviewCard(
            emoji: _selectedEmoji,
            name: _nameController.text,
            colorHex: _selectedColor,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Emoji + Color row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiInput(
                label: l10n.categoryFormIconField,
                initialValue: _selectedEmoji.isNotEmpty ? _selectedEmoji : null,
                onChanged: (emoji) => setState(() => _selectedEmoji = emoji),
                validator: (_) => _showErrors ? _validateEmoji() : null,
                autovalidateMode: _showErrors
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: ColorPalettePicker(
                  label: l10n.categoryFormColorField,
                  selectedColor: _selectedColor,
                  onChanged: (color) =>
                      setState(() => _selectedColor = color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),

          // Name field
          AppFormField(
            label: l10n.categoryFormNameField,
            showError: nomError != null,
            errorMessage: nomError ?? '',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration.collapsed(hintText: ''),
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                color: colorScheme.onSurface,
              ),
              maxLength: 30,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Delete button (edit mode only)
          if (_isEditMode) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _onDelete,
                icon: PhosphorIcon(PhosphorIconsRegular.trash, color: colorScheme.error, size: 20),
                label: Text(
                  l10n.delete,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space12),
        ],
      ),
    );
  }
}
