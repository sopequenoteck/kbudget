package fr.kksdev.budget.api.util;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Chaque cas reprend un motif observe sur des libelles nettoyes reels
 * (KKS-383), avec des noms de commercants et de personnes fictifs.
 */
class MerchantKeyTest {

    @ParameterizedTest(name = "{0} -> {1}")
    @CsvSource(delimiter = '|', quoteCharacter = '"', value = {
            // Le mois du salaire changeait la cle chaque mois
            "VIR RECU S DE: EMPLOYEUR TEST REF: SALAIRE DE Juillet 2026 | EMPLOYEUR TEST",
            "VIR RECU S DE: EMPLOYEUR TEST REF: SALAIRE DE Aout 2026    | EMPLOYEUR TEST",
            "VIR INST RE WERO DE: M JEAN TEST DATE: 18/09/2026 11:09     | M JEAN TEST",
            // Un meme commercant sous deux libelles
            "APPLE.COM/BILL                                              | APPLE",
            "APPLE                                                       | APPLE",
            "CLAUDE.AI SUBSCRIPTION                                      | CLAUDE",
            "ANTHROPIC* CLAUDE SUB                                       | ANTHROPIC CLAUDE",
            // Dates et references au milieu du libelle
            "VIR EUROPEEN Jade 06 07                                     | VIR EUROPEEN JADE",
            "ARRETE 01.04/30.06 MINIMUM FORFAITAIRE NOMBRE JOURS DEBITEURS : 48 | ARRETE MINIMUM FORFAITAIRE NOMBRE JOURS DEBITEURS",
            "COMMISSION D'INTERVENTION Calculée au 24/08/2026 pour : PRELEVEMENT EUROPEEN 5207906798 Montant : -19,99 | COMMISSION D INTERVENTION",
            // Montant retire a moitie par le nettoyage
            "FRAIS SUR SATD DE OS TRES. AMENDES DES BOUCHES DU R        | FRAIS SUR SATD DE TRES AMENDES DES BOUCHES DU R",
            // Prefixes de moyen de paiement
            "SumUp  *Pizzeria test                                       | PIZZERIA TEST",
            "UEP*SUPER U                                                 | SUPER U",
            "PSP*SWEEEK                                                  | SWEEEK",
            "MP*DAC TEST                                                 | DAC TEST",
            "PAYPAL_*LUNCH CORNER G                                      | LUNCH CORNER G",
            // Pays et numeros de magasin
            "taptap send BELGIQUE                                        | TAPTAP SEND",
            "JetBrains REPUBLIQUE TCHEQ                                  | JETBRAINS",
            "Action 4367                                                 | ACTION",
            "RELAY           4067420                                     | RELAY",
    })
    void should_normalize_label_when_it_carries_varying_details(String label, String expected) {
        assertThat(MerchantKey.of(label)).isEqualTo(expected);
    }

    @Test
    void should_ignore_case_and_accents_when_comparing_same_merchant() {
        assertThat(MerchantKey.of("Boulangerie Éclair")).isEqualTo(MerchantKey.of("BOULANGERIE ECLAIR"));
    }

    @Test
    void should_return_empty_key_when_label_is_null_or_has_no_letters() {
        assertThat(MerchantKey.of(null)).isEmpty();
        assertThat(MerchantKey.of("12/03 4067420")).isEmpty();
    }

    @Test
    void should_match_whole_words_only_when_checking_pattern_in_key() {
        assertThat(MerchantKey.containsWords("FRESH", "fresh")).isTrue();
        assertThat(MerchantKey.containsWords("SUPER U ISTRES", "super u")).isTrue();
        assertThat(MerchantKey.containsWords("REFRESHMENT BAR", "FRESH")).isFalse();
        assertThat(MerchantKey.containsWords("EASY BAR", "Y B")).isFalse();
    }

    @Test
    void should_not_match_when_pattern_or_key_is_empty() {
        assertThat(MerchantKey.containsWords("FRESH", "12")).isFalse();
        assertThat(MerchantKey.containsWords("", "FRESH")).isFalse();
    }
}
