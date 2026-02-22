import 'package:flutter/material.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?>? onChanged;
  final String label;
  final String placeholder;
  final bool clearable;
  final int searchThreshold;
  final bool enabled;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onCreateRequested;
  final FormFieldValidator<String?>? validator;
  final FormFieldSetter<String?>? onSaved;
  final AutovalidateMode? autovalidateMode;

  const CategoryPicker({
    super.key,
    required this.categories,
    this.selectedId,
    this.onChanged,
    required this.label,
    this.placeholder = 'Sélectionner...',
    this.clearable = false,
    this.searchThreshold = 5,
    this.enabled = true,
    this.onSearchChanged,
    this.onCreateRequested,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
  });

  List<SelectPickerItem> get _items => categories
      .map((c) => SelectPickerItem(
            id: c.id,
            label: c.nom,
            icon: c.icone,
            color: parseHexColor(c.couleur),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return SelectPicker(
      items: _items,
      selectedId: selectedId,
      onChanged: onChanged,
      label: label,
      placeholder: placeholder,
      clearable: clearable,
      searchThreshold: searchThreshold,
      enabled: enabled,
      emptyMessage: 'Aucune catégorie',
      onSearchChanged: onSearchChanged,
      emptyActionBuilder:
          onCreateRequested != null ? _buildCreateButton : null,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
    );
  }

  Widget _buildCreateButton(String searchTerm) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Semantics(
          button: true,
          label: 'Créer $searchTerm',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).pop();
              onCreateRequested!(searchTerm);
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '+ Créer « $searchTerm »',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
