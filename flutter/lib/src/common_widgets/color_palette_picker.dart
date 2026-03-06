import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class ColorPalettePicker extends StatelessWidget {
  static const List<String> paletteColors = [
    '#3b82f6',
    '#10b981',
    '#f59e0b',
    '#ef4444',
    '#f97316',
    '#84cc16',
    '#22c55e',
    '#06b6d4',
    '#6366f1',
    '#8b5cf6',
    '#ec4899',
    '#6b7280',
  ];

  final String? selectedColor;
  final ValueChanged<String> onChanged;
  final String label;

  const ColorPalettePicker({
    super.key,
    this.selectedColor,
    required this.onChanged,
    this.label = 'Couleur',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build display list: if selected is custom (not in palette), prepend it
    final displayColors = <String>[...paletteColors];
    if (selectedColor != null &&
        selectedColor!.isNotEmpty &&
        !paletteColors.contains(selectedColor!.toLowerCase())) {
      displayColors.insert(0, selectedColor!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            fontWeight: AppTypography.medium,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: displayColors.map((hex) {
            final isSelected =
                selectedColor?.toLowerCase() == hex.toLowerCase();
            final color = parseHexColor(hex);

            return GestureDetector(
              onTap: () => onChanged(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: colorScheme.onSurface,
                          width: 2.5,
                        )
                      : null,
                ),
                child: isSelected
                    ? PhosphorIcon(
                        PhosphorIconsBold.check,
                        size: 16,
                        color: color != null
                            ? (ThemeData.estimateBrightnessForColor(color) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            : colorScheme.onSurface,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
