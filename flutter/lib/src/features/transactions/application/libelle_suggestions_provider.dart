// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';

/// Provider Riverpod qui retourne les suggestions de libellés pour l'autocomplete.
///
/// Paramètre : la query saisie par l'utilisateur.
/// Garde : si [query.length < 2], retourne une liste vide sans appel réseau/local.
/// Délègue au repository actif (local ou remote selon [dataModeProvider]).
final libelleSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return const [];
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getLibelleSuggestions(query, limit: 20);
});
