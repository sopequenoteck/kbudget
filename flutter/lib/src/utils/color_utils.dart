import 'dart:ui';

/// Parse une couleur hexadécimale (ex: "#FF5733", "FF5733", "5733FF").
/// Retourne null si la valeur est invalide ou vide.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  final value = int.tryParse(cleaned, radix: 16);
  return value != null ? Color(value) : null;
}
