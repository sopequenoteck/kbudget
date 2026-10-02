package fr.kksdev.budget.api.dto.response;

import fr.kksdev.budget.api.enums.CategorySource;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ImportDraftLineResponseTest {

    private static ImportDraftLine.ImportDraftLineBuilder lineBuilder() {
        return ImportDraftLine.builder()
                .id(UUID.randomUUID())
                .lineNumber(1)
                .rawLabel("RAW")
                .cleanLabel("Clean")
                .amount(new BigDecimal("12.50"))
                .date(LocalDate.of(2026, Month.AUGUST, 24))
                .transactionType(TransactionType.DEPENSE)
                .status(ImportLineStatus.READY);
    }

    @Test
    void should_expose_the_reconciliation_fields_of_the_line() {
        UUID matched = UUID.randomUUID();
        UUID subscription = UUID.randomUUID();
        UUID candidate = UUID.randomUUID();
        ImportDraftLine line = lineBuilder()
                .purchaseDate(LocalDate.of(2026, Month.AUGUST, 21))
                .matchedTransactionId(matched)
                .subscriptionId(subscription)
                .matchCandidateIds(List.of(candidate))
                .build();

        ImportDraftLineResponse response = ImportDraftLineResponse.from(line);

        assertThat(response.purchaseDate()).isEqualTo(LocalDate.of(2026, Month.AUGUST, 21));
        assertThat(response.matchedTransactionId()).isEqualTo(matched);
        assertThat(response.subscriptionId()).isEqualTo(subscription);
        assertThat(response.matchCandidateIds()).containsExactly(candidate);
    }

    @Test
    void should_leave_the_reconciliation_fields_and_their_details_empty_for_a_plain_line() {
        ImportDraftLineResponse response = ImportDraftLineResponse.from(lineBuilder().build());

        assertThat(response.purchaseDate()).isNull();
        assertThat(response.matchedTransactionId()).isNull();
        assertThat(response.subscriptionId()).isNull();
        assertThat(response.matchCandidateIds()).isEmpty();
        assertThat(response.matchedTransaction()).isNull();
        assertThat(response.matchCandidates()).isEmpty();
    }

    @Test
    void should_give_no_category_source_when_the_category_has_none_or_the_line_has_no_category() {
        Category category = Category.builder().id(UUID.randomUUID()).nom("Courses").build();

        assertThat(ImportDraftLineResponse.from(lineBuilder().category(category).build()).categorySource()).isNull();
        assertThat(ImportDraftLineResponse.from(lineBuilder().categorySource(CategorySource.USER).build()).categorySource()).isNull();
        assertThat(ImportDraftLineResponse.from(lineBuilder().category(category).categorySource(CategorySource.RULE).build())
                .categorySource()).isEqualTo("RULE");
    }

    @Test
    void should_expose_the_detail_of_the_matched_transaction_and_of_the_candidates_in_the_order_of_their_identifiers() {
        ImportMatchedTransactionResponse matched = detail("Tabac");
        ImportMatchedTransactionResponse first = detail("Cafe 1");
        ImportMatchedTransactionResponse second = detail("Cafe 2");
        ImportDraftLine line = lineBuilder()
                .matchedTransactionId(matched.id())
                .matchCandidateIds(List.of(second.id(), first.id()))
                .build();

        ImportDraftLineResponse response = ImportDraftLineResponse.from(line, false,
                Map.of(matched.id(), matched, first.id(), first, second.id(), second));

        assertThat(response.matchedTransaction()).isEqualTo(matched);
        assertThat(response.matchCandidates()).containsExactly(second, first);
        assertThat(response.matchCandidateIds()).containsExactly(second.id(), first.id());
    }

    @Test
    void should_leave_out_a_transaction_that_is_not_in_the_given_details_but_keep_its_identifier() {
        ImportMatchedTransactionResponse known = detail("Cafe 1");
        UUID unknown = UUID.randomUUID();
        ImportDraftLine line = lineBuilder()
                .matchedTransactionId(unknown)
                .matchCandidateIds(List.of(unknown, known.id()))
                .build();

        ImportDraftLineResponse response = ImportDraftLineResponse.from(line, false, Map.of(known.id(), known));

        assertThat(response.matchedTransactionId()).isEqualTo(unknown);
        assertThat(response.matchedTransaction()).isNull();
        assertThat(response.matchCandidates()).containsExactly(known);
        assertThat(response.matchCandidateIds()).containsExactly(unknown, known.id());
    }

    @Test
    void should_describe_a_transaction_by_its_date_label_amount_and_type() {
        Transaction transaction = Transaction.builder().id(UUID.randomUUID()).libelle("Tabac")
                .montant(new BigDecimal("4.50")).type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, Month.SEPTEMBER, 18)).build();

        ImportMatchedTransactionResponse response = ImportMatchedTransactionResponse.from(transaction);

        assertThat(response).isEqualTo(new ImportMatchedTransactionResponse(
                transaction.getId(), LocalDate.of(2026, Month.SEPTEMBER, 18), "Tabac",
                new BigDecimal("4.50"), TransactionType.DEPENSE));
    }

    private static ImportMatchedTransactionResponse detail(String libelle) {
        return new ImportMatchedTransactionResponse(UUID.randomUUID(), LocalDate.of(2026, Month.AUGUST, 21), libelle,
                new BigDecimal("12.50"), TransactionType.DEPENSE);
    }
}
