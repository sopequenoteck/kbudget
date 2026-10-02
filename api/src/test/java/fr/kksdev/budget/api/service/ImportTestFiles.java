package fr.kksdev.budget.api.service;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/** Synthetic statement files shared by the import profile tests: fictitious merchants and references only. */
public final class ImportTestFiles {

    /** Société Générale statement, ISO-8859-1: bank header line, blank line, column header, two operations. */
    static final String SG_STATEMENT = """
            ="0000000000001596";15/09/2026;01/10/2026;2;01/10/2026;1842,37 EUR

            Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise
            16/09/2026;CARTE X1596 14/09 ;CARTE X1596 14/09 BOULANGERIE DU MARCHE 110600000000101IOPD ;-4,30;EUR
            17/09/2026;PRELEVEMENT EUROPE;PRELEVEMENT EUROPEEN 2222222222 DE: APPLE.COM/BILL ID: FR00ZZZ000001 REF: ref-0101 ;-2,99;EUR
            """;

    /** Comma-separated file of an unknown bank, UTF-8. */
    static final String OTHER_BANK_STATEMENT = """
            Booked,Memo,Value
            2026-09-16,Bakery,-4.30
            2026-09-17,Subscription,-2.99
            """;

    private static final String SG_COLUMN_HEADER =
            "Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise";

    private ImportTestFiles() {}

    /** Bank header line of an SG statement: account number, period, operation count, balance date and balance. */
    public static String sgBankHeader(String accountNumber, String balanceDate, String balance) {
        return "=\"" + accountNumber + "\";15/09/2026;01/10/2026;2;" + balanceDate + ";" + balance;
    }

    /** SG statement, ISO-8859-1, with the given bank header line and operation lines. */
    public static byte[] sgStatementOf(String bankHeader, String... operations) {
        String content = bankHeader + "\n\n" + SG_COLUMN_HEADER + "\n" + String.join("\n", operations) + "\n";
        return content.getBytes(StandardCharsets.ISO_8859_1);
    }

    public static byte[] sgStatement() {
        return SG_STATEMENT.getBytes(StandardCharsets.ISO_8859_1);
    }

    public static byte[] otherBankStatement() {
        return OTHER_BANK_STATEMENT.getBytes(StandardCharsets.UTF_8);
    }

    public static byte[] bytes(String content, Charset charset) {
        return content.getBytes(charset);
    }
}
