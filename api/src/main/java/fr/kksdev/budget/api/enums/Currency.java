package fr.kksdev.budget.api.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Currency {
    EUR("€", "Euro", 2),
    XOF("CFA", "Franc CFA (BCEAO)", 0),
    USD("$", "Dollar américain", 2),
    GBP("£", "Livre sterling", 2),
    CHF("CHF", "Franc suisse", 2),
    CAD("CA$", "Dollar canadien", 2),
    MAD("MAD", "Dirham marocain", 2);

    private final String symbol;
    private final String displayName;
    private final int decimalPlaces;
}
