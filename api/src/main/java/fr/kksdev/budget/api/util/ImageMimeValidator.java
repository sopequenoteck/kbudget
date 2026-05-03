package fr.kksdev.budget.api.util;

import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;

/**
 * Utilitaire de validation MIME par magic numbers pour les images.
 * Accepte uniquement JPEG et PNG (KKS-235 — RES-002).
 * Pas d'Apache Tika : validation custom suffisante pour 2 formats (principe YAGNI).
 */
public final class ImageMimeValidator {

    // Magic numbers JPEG : FF D8 FF
    private static final byte[] JPEG_MAGIC = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};

    // Magic numbers PNG : 89 50 4E 47 0D 0A 1A 0A
    private static final byte[] PNG_MAGIC = {
            (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
    };

    private ImageMimeValidator() {
        // Classe utilitaire — pas d'instanciation
    }

    /**
     * Vérifie si le fichier est une image JPEG ou PNG valide via ses magic numbers.
     *
     * @param file le fichier multipart à valider
     * @return true si le fichier est un JPEG ou PNG valide, false sinon
     */
    public static boolean isValidImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return false;
        }
        return detectMimeType(file) != null;
    }

    /**
     * Détecte le type MIME d'un fichier image via ses magic numbers.
     *
     * @param file le fichier multipart à analyser
     * @return "image/jpeg", "image/png", ou null si non reconnu
     */
    public static String detectMimeType(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return null;
        }
        try (InputStream is = file.getInputStream()) {
            byte[] header = new byte[PNG_MAGIC.length];
            int read = is.read(header);
            if (read < JPEG_MAGIC.length) {
                return null;
            }
            if (startsWith(header, JPEG_MAGIC)) {
                return "image/jpeg";
            }
            if (read >= PNG_MAGIC.length && startsWith(header, PNG_MAGIC)) {
                return "image/png";
            }
            return null;
        } catch (IOException e) {
            return null;
        }
    }

    private static boolean startsWith(byte[] data, byte[] prefix) {
        if (data.length < prefix.length) {
            return false;
        }
        for (int i = 0; i < prefix.length; i++) {
            if (data[i] != prefix[i]) {
                return false;
            }
        }
        return true;
    }
}
