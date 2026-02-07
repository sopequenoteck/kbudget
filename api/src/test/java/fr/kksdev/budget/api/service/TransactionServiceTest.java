package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.TransactionRequest;
import fr.kksdev.budget.api.dto.TransactionResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.TransactionRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private TransactionService transactionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Transaction buildTransaction(User user) {
        return Transaction.builder()
                .id(transactionId)
                .montant(new BigDecimal("50.00"))
                .libelle("Courses")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, 2, 7))
                .categorie("Alimentation")
                .note("Supermarché")
                .user(user)
                .build();
    }

    @Test
    void should_create_transaction_when_valid_request() {
        var user = buildUser();
        var request = new TransactionRequest(
                new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), "Alimentation", "Supermarché");
        var saved = buildTransaction(user);

        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        TransactionResponse response = transactionService.create(request, user);

        assertThat(response.id()).isEqualTo(transactionId);
        assertThat(response.montant()).isEqualByComparingTo("50.00");
        assertThat(response.libelle()).isEqualTo("Courses");
        assertThat(response.type()).isEqualTo(TransactionType.DEPENSE);
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_return_all_transactions_when_user_has_transactions() {
        var user = buildUser();
        var transactions = List.of(buildTransaction(user));

        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(transactions);

        List<TransactionResponse> result = transactionService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().libelle()).isEqualTo("Courses");
    }

    @Test
    void should_return_empty_list_when_user_has_no_transactions() {
        when(transactionRepository.findByUserIdOrderByDateDesc(userId)).thenReturn(List.of());

        List<TransactionResponse> result = transactionService.getAllByUser(userId);

        assertThat(result).isEmpty();
    }

    @Test
    void should_return_transaction_when_found_and_owned() {
        var user = buildUser();
        var transaction = buildTransaction(user);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        TransactionResponse response = transactionService.getById(transactionId, userId);

        assertThat(response.id()).isEqualTo(transactionId);
        assertThat(response.libelle()).isEqualTo("Courses");
    }

    @Test
    void should_throw_when_transaction_not_found() {
        when(transactionRepository.findById(transactionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.getById(transactionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Transaction non trouvée");
    }

    @Test
    void should_throw_when_transaction_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var transaction = buildTransaction(otherUser);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        assertThatThrownBy(() -> transactionService.getById(transactionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Transaction non trouvée");
    }

    @Test
    void should_update_transaction_when_valid() {
        var user = buildUser();
        var existing = buildTransaction(user);
        var request = new TransactionRequest(
                new BigDecimal("75.00"), "Courses modifiées", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 8), "Alimentation", "Autre magasin");

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(existing));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(existing);

        TransactionResponse response = transactionService.update(transactionId, request, userId);

        assertThat(response).isNotNull();
        verify(transactionRepository).save(existing);
    }

    @Test
    void should_delete_transaction_when_found_and_owned() {
        var user = buildUser();
        var transaction = buildTransaction(user);

        when(transactionRepository.findById(transactionId)).thenReturn(Optional.of(transaction));

        transactionService.delete(transactionId, userId);

        verify(transactionRepository).delete(transaction);
    }
}
