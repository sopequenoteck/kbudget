import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

class SelectPickerItem {
  final String id;
  final String label;
  final String? icon;
  final Color? color;
  final String? secondaryText;
  final String? imageUrl;

  const SelectPickerItem({
    required this.id,
    required this.label,
    this.icon,
    this.color,
    this.secondaryText,
    this.imageUrl,
  })  : assert(id != '', 'SelectPickerItem id must not be empty'),
        assert(label != '', 'SelectPickerItem label must not be empty');
}

class SelectPicker extends FormField<String?> {
  final List<SelectPickerItem> items;
  final ValueChanged<String?>? onChanged;
  final String label;
  final String placeholder;
  final bool clearable;
  final bool? searchable;
  final int searchThreshold;
  final String emptyMessage;
  final ValueChanged<String>? onSearchChanged;
  final Widget Function(String searchTerm)? emptyActionBuilder;

  SelectPicker({
    super.key,
    required this.items,
    String? selectedId,
    this.onChanged,
    required this.label,
    this.placeholder = 'Sélectionner...',
    this.clearable = false,
    this.searchable,
    this.searchThreshold = 5,
    this.emptyMessage = 'Aucun résultat',
    this.onSearchChanged,
    this.emptyActionBuilder,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled = true,
  }) : super(
          initialValue: selectedId,
          builder: (FormFieldState<String?> field) {
            final state = field as _SelectPickerState;
            return state._buildTrigger();
          },
        );

  @override
  FormFieldState<String?> createState() => _SelectPickerState();
}

class _SelectPickerState extends FormFieldState<String?> {
  @override
  SelectPicker get widget => super.widget as SelectPicker;

  SelectPickerItem? get _selectedItem {
    if (value == null) return null;
    final matches = widget.items.where((item) => item.id == value);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void didUpdateWidget(covariant SelectPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync with parent's selectedId
    if (widget.initialValue != oldWidget.initialValue) {
      setValue(widget.initialValue);
    }

    // Auto-reset if selected item no longer exists (FR-011)
    if (value != null && !widget.items.any((item) => item.id == value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          didChange(null);
          widget.onChanged?.call(null);
        }
      });
    }
  }

  void _onItemSelected(String id) {
    if (id == value) {
      Navigator.of(context).pop();
      return;
    }
    didChange(id);
    widget.onChanged?.call(id);
    Navigator.of(context).pop();
  }

  void _onClear() {
    didChange(null);
    widget.onChanged?.call(null);
  }

  void _openModal() {
    final showSearch = widget.searchable == true ||
        (widget.searchable == null &&
            widget.items.length >= widget.searchThreshold);

    if (showSearch) {
      final searchNotifier = ValueNotifier<String>('');
      AppModal.show(
        context,
        title: widget.placeholder,
        headerActions: _buildSearchField(searchNotifier),
        child: ValueListenableBuilder<String>(
          valueListenable: searchNotifier,
          builder: (ctx, query, _) => _buildItemsList(ctx, query),
        ),
        onClose: () {},
      );
    } else {
      AppModal.show(
        context,
        title: widget.placeholder,
        child: _buildItemsList(context, ''),
        onClose: () {},
      );
    }
  }

  Widget _buildSearchField(ValueNotifier<String> notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space2,
        horizontal: AppSpacing.space3,
      ),
      child: TextField(
        style: TextStyle(
          fontSize: AppTypography.sizeMd,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration.collapsed(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(
            fontSize: AppTypography.sizeMd,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        onChanged: (query) {
          notifier.value = query;
          widget.onSearchChanged?.call(query);
        },
      ),
    );
  }

  Widget _buildItemsList(BuildContext ctx, String searchQuery) {
    final colorScheme = Theme.of(ctx).colorScheme;
    final filteredItems = searchQuery.isEmpty
        ? widget.items
        : widget.items
            .where((i) =>
                i.label.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    if (filteredItems.isEmpty) {
      if (widget.emptyActionBuilder != null) {
        return widget.emptyActionBuilder!(searchQuery);
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
          child: Text(
            widget.emptyMessage,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          filteredItems.map((item) => _buildItemTile(ctx, item)).toList(),
    );
  }

  Widget _buildImageWidget(String imageUrl, double size) {
    if (imageUrl.startsWith('assets/')) {
      return SvgPicture.asset(imageUrl, width: size, height: size);
    }
    if (imageUrl.contains('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(imageUrl.substring(commaIndex + 1));
          return Image.memory(bytes, width: size, height: size);
        }
      } catch (_) {
        // fall through
      }
    }
    return SizedBox(width: size, height: size);
  }

  Widget _buildItemTile(BuildContext ctx, SelectPickerItem item) {
    final colorScheme = Theme.of(ctx).colorScheme;
    final isSelected = item.id == value;

    return Semantics(
      label: item.label,
      toggled: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemSelected(item.id),
        child: Container(
          height: AppSpacing.space12,
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Row(
            children: [
              if (item.imageUrl != null) ...[
                _buildImageWidget(item.imageUrl!, 24),
                const SizedBox(width: AppSpacing.space3),
              ] else if (item.icon != null) ...[
                Text(item.icon!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.space3),
              ],
              if (item.color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.secondaryText != null)
                Text(
                  item.secondaryText!,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrigger() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedItem = _selectedItem;
    final hasSelection = selectedItem != null;
    final showError = hasError && errorText != null && errorText!.isNotEmpty;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          label: selectedItem?.label ?? widget.placeholder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.space2),
              // Container
              GestureDetector(
                onTap: widget.enabled ? _openModal : null,
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  curve: AppDurations.easeInOut,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                    horizontal: AppSpacing.space4,
                  ),
                  child: Row(
                    children: [
                      if (hasSelection) ...[
                        if (selectedItem.imageUrl != null) ...[
                          _buildImageWidget(selectedItem.imageUrl!, 24),
                          const SizedBox(width: AppSpacing.space3),
                        ] else if (selectedItem.icon != null) ...[
                          Text(
                            selectedItem.icon!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppSpacing.space3),
                        ],
                        if (selectedItem.color != null) ...[
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: selectedItem.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space3),
                        ],
                        Expanded(
                          child: Text(
                            selectedItem.label,
                            style: TextStyle(
                              fontSize: AppTypography.sizeMd,
                              fontWeight: AppTypography.medium,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedItem.secondaryText != null) ...[
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            selectedItem.secondaryText!,
                            style: TextStyle(
                              fontSize: AppTypography.sizeSm,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ] else
                        Expanded(
                          child: Text(
                            widget.placeholder,
                            style: TextStyle(
                              fontSize: AppTypography.sizeMd,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.space2),
                      if (widget.clearable && hasSelection && widget.enabled)
                        GestureDetector(
                          onTap: _onClear,
                          child: PhosphorIcon(
                            PhosphorIconsBold.x,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        PhosphorIcon(
                          PhosphorIconsRegular.caretDown,
                          color: colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
              // Error message
              AnimatedSize(
                duration: AppDurations.normal,
                curve: AppDurations.easeInOut,
                alignment: Alignment.topLeft,
                child: showError
                    ? Padding(
                        padding:
                            const EdgeInsets.only(top: AppSpacing.space1),
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            fontSize: AppTypography.sizeXs,
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
