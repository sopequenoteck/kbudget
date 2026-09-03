// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';

/// Conteneur arrondi `surfaceContainer` regroupant des items avec des
/// dividers internes automatiques.
///
/// Insère un [Divider] de 1px entre chaque paire d'enfants (pas après le
/// dernier). Le conteneur a un `borderRadius` de [AppRadius.xl] et la
/// couleur `colorScheme.surfaceContainer`.
///
/// Optimisé pour 5–30 items max (pas de virtualisation interne).
///
/// Exemple d'usage :
/// ```dart
/// ListGroup(
///   children: [
///     ListTile(title: Text('Item 1')),
///     ListTile(title: Text('Item 2')),
///     ListTile(title: Text('Item 3')),
///   ],
/// )
/// ```
class ListGroup extends StatelessWidget {
  /// Crée un groupe de widgets avec séparateurs et fond arrondi.
  const ListGroup({
    super.key,
    required this.children,
  });

  /// Items à grouper. `n - 1` dividers seront insérés entre eux.
  final List<Widget> children;

  List<Widget> _intersperseDividers(List<Widget> items, Color color) {
    if (items.isEmpty) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Divider(height: 1, thickness: 1, color: color));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        color: colorScheme.surfaceContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _intersperseDividers(children, colorScheme.outlineVariant),
      ),
    );
  }
}
