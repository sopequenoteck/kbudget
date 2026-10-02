package fr.kksdev.budget.api.service;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * What the bank header of a statement gave (KKS-384). Every component is
 * nullable: an unreadable value, or a profile without a header, is absent.
 *
 * @param profileKey    key of the profile, see {@link ImportProfileDetector.Detection#profileKey()}
 * @param accountSuffix last four digits of the account number; the full number is never kept
 * @param balance       balance given by the bank
 * @param balanceDate   date of that balance
 */
public record StatementInfo(String profileKey, String accountSuffix, BigDecimal balance, LocalDate balanceDate) {

    public static final StatementInfo NONE = new StatementInfo(null, null, null, null);
}
