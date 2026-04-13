package fr.kksdev.budget.api;

import java.text.Normalizer;

/**
 * UDF H2 simulant la fonction PostgreSQL UNACCENT.
 * Utilisée uniquement dans les tests @DataJpaTest (H2 en mémoire).
 */
public final class H2UnaccentFunction {

    private H2UnaccentFunction() {}

    public static String unaccent(String s) {
        if (s == null) return null;
        String normalized = Normalizer.normalize(s, Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
    }
}
