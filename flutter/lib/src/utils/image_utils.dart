import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Utilitaires pour la gestion des images base64 (portabilité Flutter ↔ Angular).
class ImageUtils {
  ImageUtils._();

  /// Détecte si une chaîne est un data URI base64 (ex: `data:image/jpeg;base64,...`).
  static bool isBase64DataUri(String? value) {
    if (value == null) return false;
    return value.startsWith('data:image/');
  }

  /// Convertit un fichier image en data URI base64.
  /// Retourne `data:image/jpeg;base64,...` (JPEG par défaut).
  static String fileToBase64DataUri(File file) {
    final bytes = file.readAsBytesSync();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  /// Décode un data URI base64 en bytes pour `Image.memory()`.
  static Uint8List base64DataUriToBytes(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      throw ArgumentError('Data URI invalide : pas de virgule trouvée');
    }
    return base64Decode(dataUri.substring(commaIndex + 1));
  }
}
