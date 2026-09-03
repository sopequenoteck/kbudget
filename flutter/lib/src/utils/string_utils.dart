// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:diacritic/diacritic.dart';

/// Normalise une chaîne pour la recherche : lowercase + suppression des
/// diacritiques (accents) + trim.
///
/// Exemple : `normalizeForSearch('Café  ')` → `'cafe'`.
///
/// Utilisé par les composants de recherche (ex: [CategorySelectExpand])
/// pour permettre des matches insensibles à la casse et aux accents.
String normalizeForSearch(String input) =>
    removeDiacritics(input.toLowerCase()).trim();
