package fr.kksdev.budget.api.util;

import fr.kksdev.budget.api.enums.TransactionType;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.util.HexFormat;

/**
 * Empreinte d'une ligne de releve (KKS-382) : ce qui identifie une operation
 * bancaire d'un fichier a l'autre.
 *
 * <p>Elle ne porte que sur les donnees du fichier — date comptable, montant,
 * sens, libelle brut — jamais sur le libelle nettoye, qui depend de la version
 * de {@code LabelCleaningService}. Deux lignes identiques d'un meme releve ont
 * la meme empreinte : ce sont deux operations reelles, que la deduplication
 * distingue par leur nombre d'occurrences.
 */
public final class ImportFingerprint {

    private static final String SEPARATOR = "|";

    private ImportFingerprint() {}

    public static String of(LocalDate date, BigDecimal amount, TransactionType type, String rawLabel) {
        String canonical = date + SEPARATOR
                + amount.stripTrailingZeros().toPlainString() + SEPARATOR
                + type.name() + SEPARATOR
                + normalizeLabel(rawLabel);
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(canonical.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }

    private static String normalizeLabel(String rawLabel) {
        return rawLabel == null ? "" : rawLabel.trim().replaceAll("\\s+", " ");
    }
}
