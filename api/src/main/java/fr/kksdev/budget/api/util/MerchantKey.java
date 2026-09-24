package fr.kksdev.budget.api.util;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Cle commercant d'un libelle de transaction (KKS-383) : ce qui reste d'un
 * libelle une fois retire tout ce qui varie d'une operation a l'autre chez un
 * meme commercant — dates, references, montants, mois, pays, prefixes de
 * moyen de paiement.
 *
 * <p>Elle sert uniquement a rapprocher les operations d'un meme commercant
 * pour la categorisation. Elle ne remplace jamais le libelle affiche ni le
 * libelle nettoye : la reconnaissance des lignes deja importees (KKS-382)
 * compare le libelle nettoye, qui ne doit pas changer.
 */
public final class MerchantKey {

    // Les espaces sont ramenes a un seul avant tout : les motifs suivants n'ont
    // ainsi jamais deux quantificateurs qui se disputent les memes caracteres.
    private static final Pattern DIACRITICS = Pattern.compile("\\p{M}+");
    private static final Pattern WHITESPACE = Pattern.compile("\\s+");
    /** Virement recu : on garde l'emetteur. "VIR RECU S DE: CARSAT ..." -> "CARSAT ...". */
    private static final Pattern INCOMING_TRANSFER = Pattern.compile("^VIR (?:RECU|INST RE)(?: S)?(?: WERO)? DE: ?");
    /** Tout ce qui suit une reference, un motif ou une date d'execution varie a chaque operation. */
    private static final Pattern TRAILING_DETAILS = Pattern.compile(" ?\\b(?:REF|MOTIF|DATE|ID|IBAN) ?:.*$");
    private static final Pattern CALCULATION_DETAILS = Pattern.compile(" ?\\bCALCULEE AU\\b.*$");
    /** "APPLE.COM/BILL" et "APPLE" designent le meme commercant. */
    private static final Pattern DOMAIN_SUFFIX = Pattern.compile("\\.(?:COM|FR|NET|ORG|IO|AI)\\b(?:/\\S*)?");
    private static final Pattern PAYMENT_PREFIX = Pattern.compile("\\b(?:SUMUP|UEP|PSP|MP|PAYPAL_?|SQ|ZTL) ?\\*");
    private static final Pattern MONTH = Pattern.compile(
            "\\b(JANVIER|FEVRIER|MARS|AVRIL|MAI|JUIN|JUILLET|AOUT|SEPTEMBRE|OCTOBRE|NOVEMBRE|DECEMBRE)\\b");
    private static final Pattern COUNTRY = Pattern.compile(
            "\\b(IRLANDE|PAYS-BAS|ETATS-UNIS D'AME\\w*|LUXEMBOURG|ROYAUME-UNI|ALLEMAGNE|BELGIQUE"
                    + "|REPUBLIQUE TCHEQ\\w*|ESPAGNE|ITALIE|SUISSE)\\b");
    private static final Pattern ELECTRONIC_COMMERCE = Pattern.compile("\\bCOMMERCE ELECTRONIQUE\\b");
    /** Reste d'un montant "450,00 EUROS" dont le nettoyage n'a retire que "450,00 EUR". */
    private static final Pattern ORPHAN_AMOUNT_UNIT = Pattern.compile("\\bDE OS\\b");
    private static final Pattern NON_LETTERS = Pattern.compile("[^A-Z]+");
    private static final Pattern TRAILING_SUBSCRIPTION = Pattern.compile("(?: (?:SUBSCRIPTION|SUBSCR|SUB))+$");

    private MerchantKey() {}

    public static String of(String label) {
        if (label == null) {
            return "";
        }
        String key = DIACRITICS.matcher(Normalizer.normalize(label, Normalizer.Form.NFD)).replaceAll("")
                .toUpperCase(Locale.ROOT)
                .trim();
        key = WHITESPACE.matcher(key).replaceAll(" ");
        key = INCOMING_TRANSFER.matcher(key).replaceFirst("");
        key = TRAILING_DETAILS.matcher(key).replaceFirst("");
        key = CALCULATION_DETAILS.matcher(key).replaceFirst("");
        key = DOMAIN_SUFFIX.matcher(key).replaceAll("");
        key = PAYMENT_PREFIX.matcher(key).replaceAll(" ");
        key = MONTH.matcher(key).replaceAll(" ");
        key = COUNTRY.matcher(key).replaceAll(" ");
        key = ELECTRONIC_COMMERCE.matcher(key).replaceAll(" ");
        key = ORPHAN_AMOUNT_UNIT.matcher(key).replaceAll("DE");
        key = NON_LETTERS.matcher(key).replaceAll(" ").trim();
        return TRAILING_SUBSCRIPTION.matcher(key).replaceFirst("");
    }

    /**
     * Vrai si {@code pattern}, ramene a une cle, apparait dans la cle du libelle
     * comme suite de mots entiers : "FRESH" reconnait "FRESH" mais pas "REFRESHMENT",
     * et une cle courte comme "Y B" ne reconnait pas "EASY BAR".
     */
    public static boolean containsWords(String labelKey, String pattern) {
        String patternKey = of(pattern);
        if (patternKey.isEmpty() || labelKey == null || labelKey.isEmpty()) {
            return false;
        }
        return (" " + labelKey + " ").contains(" " + patternKey + " ");
    }
}
