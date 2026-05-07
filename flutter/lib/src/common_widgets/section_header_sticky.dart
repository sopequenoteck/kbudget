import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_spacing.dart';

/// En-tête sticky d'une section dans une liste scrollable.
///
/// Doit être inséré comme un [Sliver] dans un [CustomScrollView].
/// Hauteur fixe 48px. Le fond bascule de transparent vers
/// [ColorScheme.surfaceContainerHighest] dès que le header est collé au top
/// (`shrinkOffset > 0`), avec une transition animée [AppDurations.normal].
///
/// Exemple d'usage :
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SectionHeaderSticky(
///       title: 'Transactions',
///       count: 24,
///       actions: [IconButton(icon: Icon(Icons.filter_list), onPressed: ...)],
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
///
/// Incompatible avec [NestedScrollView] (cf. R-3 du plan).
class SectionHeaderSticky extends StatelessWidget {
  /// Crée un en-tête sticky pour une section de liste.
  const SectionHeaderSticky({
    super.key,
    required this.title,
    this.count,
    this.actions,
  });

  /// Titre de la section (ex : « Transactions »).
  final String title;

  /// Compteur optionnel affiché à droite du titre (ex : `24`).
  final int? count;

  /// Boutons d'action optionnels affichés à l'extrémité droite (ex : filtre).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate(
        title: title,
        count: count,
        actions: actions,
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate({
    required this.title,
    this.count,
    this.actions,
  });

  final String title;
  final int? count;
  final List<Widget>? actions;

  static const double _kHeight = 48.0;

  @override
  double get minExtent => _kHeight;

  @override
  double get maxExtent => _kHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: _kHeight,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        color: shrinkOffset > 0
            ? colorScheme.surfaceContainerHighest
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: AppSpacing.space2),
              Text(
                count.toString(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
            const Spacer(),
            if (actions != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.count != count ||
        !listEquals(oldDelegate.actions, actions);
  }
}
