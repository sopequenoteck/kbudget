// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

class EmojiInput extends FormField<String> {
  final String label;
  final ValueChanged<String>? onChanged;
  final String placeholder;

  EmojiInput({
    super.key,
    required this.label,
    this.onChanged,
    this.placeholder = '...',
    super.initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled = true,
  }) : super(
          builder: (FormFieldState<String> field) {
            final state = field as _EmojiInputState;
            return state._buildTrigger();
          },
        );

  @override
  FormFieldState<String> createState() => _EmojiInputState();
}

class _EmojiInputState extends FormFieldState<String> {
  @override
  EmojiInput get widget => super.widget as EmojiInput;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  void didUpdateWidget(covariant EmojiInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setValue(widget.initialValue);
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    didChange(emoji.emoji);
    widget.onChanged?.call(emoji.emoji);
    Navigator.of(context).pop();
  }

  void _openPicker() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) {
        return _EmojiPickerSheet(
          colorScheme: colorScheme,
          onEmojiSelected: _onEmojiSelected,
        );
      },
    );
  }

  Widget _buildTrigger() {
    final colorScheme = Theme.of(context).colorScheme;
    final showError = hasError && errorText != null && errorText!.isNotEmpty;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
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
          // Trigger box 48x48
          Semantics(
            button: true,
            label: _hasValue ? value : widget.placeholder,
            child: GestureDetector(
              onTap: widget.enabled ? _openPicker : null,
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: AppDurations.easeInOut,
                width: AppSpacing.space12,
                height: AppSpacing.space12,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                alignment: Alignment.center,
                child: _hasValue
                    ? Text(
                        value!,
                        style: const TextStyle(fontSize: AppTypography.size2xl),
                      )
                    : Text(
                        widget.placeholder,
                        style: TextStyle(
                          fontSize: AppTypography.sizeMd,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                    padding: const EdgeInsets.only(top: AppSpacing.space1),
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
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  final ColorScheme colorScheme;
  final void Function(Emoji emoji) onEmojiSelected;

  const _EmojiPickerSheet({
    required this.colorScheme,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.space2),
              width: AppSpacing.space8,
              height: AppSpacing.space1,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space2,
              AppSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choisir un emoji',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Fermer',
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const PhosphorIcon(PhosphorIconsBold.x, size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Emoji picker
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) =>
                  onEmojiSelected(emoji),
              config: Config(
                height: double.infinity,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 28,
                  backgroundColor: colorScheme.surface,
                  noRecents: const Text(
                    'Aucun emoji récent',
                    style: TextStyle(fontSize: AppTypography.sizeXl),
                  ),
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: colorScheme.surface,
                  indicatorColor: colorScheme.primary,
                  iconColorSelected: colorScheme.primary,
                  iconColor: colorScheme.onSurfaceVariant,
                  dividerColor: colorScheme.outlineVariant,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: colorScheme.surface,
                  buttonIconColor: colorScheme.onSurfaceVariant,
                  hintText: 'Rechercher un emoji...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
