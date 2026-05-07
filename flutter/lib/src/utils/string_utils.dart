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
